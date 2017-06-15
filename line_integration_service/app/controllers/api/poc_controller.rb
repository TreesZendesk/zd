class Api::PocController < ApplicationController
  skip_before_action :verify_authenticity_token

  def vfs_visa
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Request-Method'] = '*'
    render json: {
      visa: [
        {
          "Passport Number": "P2789052",
          "Application Number": "26688215",
          "Visa Status": "Approved",
          "Passport Status": "With Visa Office",
          "Registered Email": "aanyax.kapoor@gmail.com",
          "Visiting Country": "UK",
          "Residing Country": "India",
          "City": "Bangalore"
        },
        {
          "Passport Number": "B8740564",
          "Application Number": "42111035",
          "Visa Status": "Rejected",
          "Passport Status": "With Courier Agency",
          "Registered Email": "jam@gmail.com",
          "Visiting Country": "Germany",
          "Residing Country": "India",
          "City": "Mumbai"
        }
      ]
    }
  end

  def vfs_courier
    render json: {
      courier: [
        {
          "Passport Number": "P2789052",
          "Application Number": "26688215",
          "Courier Status": "In-scan"
        },
        {
          "Passport Number": "B8740564",
          "Application Number": "42111035",
          "Courier Status": "Out-scan"
        }
      ]
    }
  end

  def ig_verify
    render json: params['hub.challenge']
  end
end
