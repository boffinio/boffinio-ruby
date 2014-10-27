module BoffinIO 
  class Subscription < APIResource
    include BoffinIO::APIOperations::Create
    include BoffinIO::APIOperations::Update

    def url
      "#{Customer.url}/#{CGI.escape(customer)}/subscriptions/#{CGI.escape(id)}"
    end
  end
end