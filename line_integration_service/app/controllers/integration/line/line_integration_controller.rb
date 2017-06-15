class Integration::Line::LineIntegrationController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :allow_iframe_requests # just for development

  require "json"
  require 'line/bot'
  require 'rest-client'

  def admin
    @name = integration_params[:name]
    @instance_push_id = integration_params[:instance_push_id]
    @zendesk_access_token = integration_params[:zendesk_access_token]

    @metadata = integration_params[:metadata]
    if !integration_params[:metadata].empty?
      @metadata = JSON.parse(integration_params[:metadata])
      @line_channel_id = @metadata['line_channel_id']
      @line_channel_secret = @metadata['line_channel_secret']
      @line_channel_access_token = @metadata['line_channel_access_token']
      @type = "update"
    else
      @type = "new"
    end
    @state = integration_params[:state]
    @return_url = integration_params[:return_url]
    @subdomain = integration_params[:subdomain]
    @locale = integration_params[:locale]
    @error = ""

    respond_to do |format|
      format.html { render template: "line_integration/admin" }
    end
  end

  def pull
    metadata = JSON.parse(integration_params[:metadata])
    line_channel_id = metadata['line_channel_id']
    line_channel_secret = metadata['line_channel_secret']
    line_channel_access_token = metadata['line_channel_access_token']

    jobs = Job.where(channel_id: line_channel_id, status: 'new')
    resources = []
    jobs.each do |job|
      resource = {
        external_id: job.external_resource.external_id,
        message: job.external_resource.message,
        thread_id: job.external_resource.thread_id,
        created_at: job.external_resource.created_at,
        author: {
          external_id: job.external_resource.author.author_id,
          name: job.external_resource.author.name,
          image_url: job.external_resource.author.image_url
        },
        allow_channelback: true
      }

      job.status = 'done'
      job.save
      resources.push(resource)
    end

    render json: {external_resources: resources, state: "", metadata_needs_update: false}, status: :ok
  end

  def channelback
    metadata = JSON.parse(integration_params[:metadata])
    line_channel_id = metadata['line_channel_id']
    line_channel_secret = metadata['line_channel_secret']
    line_channel_access_token = metadata['line_channel_access_token']

    message = {
      type: 'text',
      text: integration_params[:message]
    }
    client = Line::Bot::Client.new { |config|
        config.channel_secret = line_channel_secret
        config.channel_token = line_channel_access_token
    }

    response = client.push_message(integration_params[:recipient_id], message)

    render json: {external_id: integration_params[:external_id]}, status: :ok
  end

  def clickthrough
    render json: { success: true }
  end

  def line_webhook
    @channel = Channel.find_by(channel_id: integration_params[:channel_id])
    events = integration_params[:events].first

    if events[:type] == "message"
      # validate Request X-Line-Signature
      channel_secret = @channel.channel_secret
      channel_access_token = @channel.channel_access_token
      http_request_body = request.raw_post
      hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, channel_secret, http_request_body)
      signature = Base64.strict_encode64(hash)

      if request.headers["X-Line-Signature"] == signature
        @user = save_user(events[:source][:userId], channel_secret, channel_access_token)

        if @user
          if events[:message][:type] == "text"
            payload = text_payload(events)
          end

          if events[:message][:type] == "image"
            payload = image_payload(events)
          end

          if events[:message][:type] == "sticker"
            payload = sticker_payload(events)
          end

          if events[:message][:type] == "video" || events[:message][:type] == "audio"
            payload = video_payload(events)
          end

          if events[:message][:type] == "location"
            payload = location_payload(events)
          end

          response = RestClient.post "https://#{@channel.zendesk_subdomain}.zendesk.com/api/v2/any_channel/push", payload, {content_type: 'application/json', accept: "application/json", authorization: "Bearer #{@channel.zendesk_access_token}"}
          render json: { external_resource: response, success: true }, status: :ok
        end
      else
        render json: { success: false }, status: :ok
      end
    else
      render json: { success: true }, status: :ok
    end
  end

  def text_payload(events)
    {
      instance_push_id: @channel.instance_push_id,
      external_resources: [
        {
          external_id: events[:message][:id],
          message: events[:message][:text],
          thread_id: events[:source][:userId],
          created_at: DateTime.now.to_s,
          author: {
            external_id: @user.author_id,
            name: @user.name,
            image_url: @user.image_url
          },
          allow_channelback: true
        }
      ]
    }
  end

  def image_payload(events)
    client = Line::Bot::Client.new { |config|
      config.channel_secret = @channel.channel_secret
      config.channel_token = @channel.channel_access_token
    }
    response = client.get_message_content(events[:message][:id])

    if response.code == "200"
      filename = path = response['content-disposition'].split("filename=")[1].gsub!("\"","").strip
      path = Rails.root.join('public', filename)

      # create file in public uploads
      File.open(path, 'wb') do |file|
        file.write(response.body)
      end

      payload = {
        instance_push_id: @channel.instance_push_id,
        external_resources: [
          {
            external_id: events[:message][:id],
            message: 'Image chat',
            html_message: "<img src='#{root_url}#{filename}'>",
            thread_id: events[:source][:userId],
            created_at: DateTime.now.to_s,
            author: {
              external_id: @user.author_id,
              name: @user.name,
              image_url: @user.image_url
            },
            allow_channelback: true
          }
        ]
      }
    end

    payload
  end

  def video_payload(events)
    client = Line::Bot::Client.new { |config|
      config.channel_secret = @channel.channel_secret
      config.channel_token = @channel.channel_access_token
    }
    response = client.get_message_content(events[:message][:id])

    if response.code == "200"
      filename = path = response['content-disposition'].split("filename=")[1].gsub!("\"","").strip
      path = Rails.root.join('public', filename)

      # create file in public uploads
      File.open(path, 'wb') do |file|
        file.write(response.body)
      end

      payload = {
        instance_push_id: @channel.instance_push_id,
        external_resources: [
          {
            external_id: events[:message][:id],
            message: 'Video/Audio chat',
            html_message: "<video width='320' height='240' controls>
                            <source src='#{root_url}#{filename}' type='video/mp4'>
                            Your browser does not support the video/audio tag.
                          </video>
                          <p>
                            You can go to this <a href='#{root_url}#{filename}'>link</a> to view the file.
                          </p>
                          ",
            thread_id: events[:source][:userId],
            created_at: DateTime.now.to_s,
            author: {
              external_id: @user.author_id,
              name: @user.name,
              image_url: @user.image_url
            },
            allow_channelback: true
          }
        ]
      }
    end

    payload
  end

  def sticker_payload(events)
    {
      instance_push_id: @channel.instance_push_id,
      external_resources: [
        {
          external_id: events[:message][:id],
          message: 'Sticket chat',
          html_message: "<img src='http://bot-stickershop.line-apps.com/products/0/0/100/#{events[:message][:packageId]}/PC/stickers/#{events[:message][:stickerId]}.png'>",
          thread_id: events[:source][:userId],
          created_at: DateTime.now.to_s,
          author: {
            external_id: @user.author_id,
            name: @user.name,
            image_url: @user.image_url
          },
          allow_channelback: true
        }
      ]
    }
  end

  def location_payload(events)
    {
      instance_push_id: @channel.instance_push_id,
      external_resources: [
        {
          external_id: events[:message][:id],
          message: 'Location chat',
          html_message: "The user sent a location. <br>
                        <b>Title:</b> #{events[:message][:title]} <br>
                        <b>Address:</b> #{events[:message][:address]} <br>
                        <b>Latitude:</b> #{events[:message][:latitude]} <br>
                        <b>Longitude:</b> #{events[:message][:longitude]} <br><br>

                        <a href='https://www.google.com/maps/@#{events[:message][:latitude]},#{events[:message][:longitude]},10z?hl=en'>
                          <img border='0' src='https://maps.googleapis.com/maps/api/staticmap?center=#{events[:message][:latitude]},#{events[:message][:longitude]}&size=400x400&markers=color:green|label:L|#{events[:message][:latitude]},#{events[:message][:longitude]}&markers=size:tiny|color:green&zoom=16' alt='#{events[:message][:address]}'>
                        </a>",
          thread_id: events[:source][:userId],
          created_at: DateTime.now.to_s,
          author: {
            external_id: @user.author_id,
            name: @user.name,
            image_url: @user.image_url
          },
          allow_channelback: true
        }
      ]
    }
  end

  def save_user(user_id, channel_secret, channel_access_token)
    client = Line::Bot::Client.new { |config|
      config.channel_secret = channel_secret
      config.channel_token = channel_access_token
    }
    response = client.get_profile(user_id)
    if response.code == "200"
      @author = Author.find_or_initialize_by(author_id: user_id)
      contact = JSON.parse(response.body)
      @author.name = contact['displayName']
      @author.image_url = contact['pictureUrl']
      # contact['statusMessage']
      @author.save
    end

    @author
  end

  def send_reply_url
    @name = integration_params[:name]
    @subdomain = integration_params[:subdomain]
    @locale = integration_params[:locale]
    @instance_push_id = integration_params[:instance_push_id]
    @zendesk_access_token = integration_params[:zendesk_access_token]
    @metadata = Hash.new
    @metadata['line_channel_id'] = integration_params[:line_channel_id]
    @metadata['line_channel_secret'] = integration_params[:line_channel_secret]
    @metadata['line_channel_access_token'] = integration_params[:line_channel_access_token]
    @line_channel_id = @metadata['line_channel_id']
    @line_channel_secret = @metadata['line_channel_secret']
    @line_channel_access_token = @metadata['line_channel_access_token']
    @return_url = integration_params[:return_url]
    @state = {}


    channel = Channel.find_or_initialize_by(zendesk_subdomain: @subdomain)

    if integration_params[:type] == "new" && !channel.channel_id.nil?
      @error = "Subdomain already exists."
      @type = integration_params[:type]
      respond_to do |format|
        format.html { render template: "line_integration/admin" }
      end
    else
      channel.name = @name
      channel.channel_id = @metadata['line_channel_id']
      channel.channel_secret = @metadata['line_channel_secret']
      channel.channel_access_token = @metadata['line_channel_access_token']
      channel.zendesk_locale = @locale
      channel.instance_push_id = @instance_push_id
      channel.zendesk_access_token = @zendesk_access_token
      channel.save

      respond_to do |format|
        format.html { render template: "line_integration/return_reply" }
      end
    end
  end

  def oauth_redirect
    render json: { success: true }, status: :ok
  end

  def close_ticket_request
    render json: { success: true }, status: :ok
  end

  protected

  def allow_iframe_requests
    request.headers["CONTENT_TYPE"]=='application/json'
    response.headers.delete('X-Frame-Options')
  end

  private

  def integration_params
    params.permit(
      # Zendesk Channel Framework params
      :instance_push_id,
      :zendesk_access_token,
      :name,
      :metadata,
      :state,
      :return_url,
      :subdomain,
      :locale,
      :line_channel_id,
      :line_channel_secret,
      :line_channel_access_token,
      :type,

      #Zendesk channelback
      :message,
      :parent_id,
      :recipient_id,
      :request_unique_identifier,

      # LINE params
      :channel_id,
      {
        :events => [
           :type,
           :replyToken,
           {
             :source => [
               :userId,
               :type
             ]
           },
           :timestamp,
           {
              :message => [
               :type,
               :id,
               :text,
               :title,
               :address,
               :latitude,
               :longitude,
               :packageId,
               :stickerId
             ]
           }
        ]
      }
    )
  end
end
