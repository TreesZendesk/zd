Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'home#index'
  namespace 'integration' do
    namespace 'line' do

      # Zendesk Channel Framework API Routes
      post '/admin', to: 'line_integration#admin'
      post '/pull', to: 'line_integration#pull'
      post '/channelback', to: 'line_integration#channelback'
      get '/clickthrough', to: 'line_integration#clickthrough'

      post '/send_reply_url', to: 'line_integration#send_reply_url'
      get '/oauth_redirect', to: 'line_integration#oauth_redirect'

      # Zendesk HC
      post '/close_ticket_request', to: 'line_integration#close_ticket_request'

      # Line Messaging API Routes
      post '/line_webhook', to: 'line_integration#line_webhook'
    end
  end

  namespace 'api' do
    get 'vfs/visa', to: 'poc#vfs_visa'
    get 'vfs/courier', to: 'poc#vfs_courier'
    match 'ig/verify', to: 'poc#ig_verify', via: [:get, :post]
  end
end
