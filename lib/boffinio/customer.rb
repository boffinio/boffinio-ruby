API_URL = "customers"

module BoffinIO 
  class Customer < APIResource
    include BoffinIO::APIOperations::List
    include BoffinIO::APIOperations::Create
    include BoffinIO::APIOperations::Update
   
   def cancel_subscription(params={})
      response, api_key = BoffinIO.request(:delete, subscriptions_url, @api_key, params)
      refresh_from({ :subscription => response }, api_key, true)
      subscription
    end

    def update_subscription(params)
      response, api_key = BoffinIO.request(:post, subscriptions_url, @api_key, params)
      refresh_from({ :subscription => response }, api_key, true)
      subscription
    end

    def create_subscription(params)
      response, api_key = BoffinIO.request(:post, subscriptions_url, @api_key, params)
      refresh_from({ :subscription => response }, api_key, true)
      subscription
    end

  private
    def subscription_url
      url + '/subscription'
    end

    def subscriptions_url
      url + '/subscriptions'
    end
  end
end