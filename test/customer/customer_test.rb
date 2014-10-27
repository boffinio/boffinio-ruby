require './test/test_helper'

class BoffinIOCustomerTest < Minitest::Test
  def test_exists
    assert BoffinIO::Customer
  end

  def test_it_gives_back_a_single_customer
    VCR.use_cassette('one_customer') do
      customer = BoffinIO::Customer.retrieve("1398")
      assert_equal BoffinIO::Customer, customer.class

      # Check that the fields are accessible by our model
      assert_equal "1398", customer.ref_id
      assert_equal "Tim Williams", customer.description
    end
  end

  def test_it_gives_back_all_customers
    VCR.use_cassette('all_customers') do
      result = BoffinIO::Customer.all

      # Make sure we got all the cars
      assert_equal 11, result.count

      # Make sure that the JSON was parsed
      assert result.kind_of?(BoffinIO::ListObject)
      customers = result.data
      assert customers.first.kind_of?(BoffinIO::Customer)
    end
  end

  def test_it_creates_one_customer
    VCR.use_cassette('create_customer') do
      customer = BoffinIO::Customer.create(
        ref_id: "test1234", 
        description: "Tim Williams",
        email: "tim@example.com"
      )

      # Make sure we got all the cars
      assert_equal "test1234", customer.ref_id
      assert_equal "Tim Williams", customer.description
      assert_equal "tim@example.com", customer.email
    end
  end

  def test_it_updates_a_named_customer
    VCR.use_cassette('one_customer') do
      customer = BoffinIO::Customer.retrieve("1398")
      VCR.use_cassette('update_customer', :record => :new_episodes) do
        customer.email="timwilliams@example.com"
        result = customer.save
        assert_equal "timwilliams@example.com",result.email
      end
    end
  end

  def test_it_creates_one_subscription
    VCR.use_cassette('one_customer') do
      customer = BoffinIO::Customer.retrieve("1398")
      VCR.use_cassette('create_subscription') do
        metadata = {:provider => "heroku"}
        subscription = customer.create_subscription(
          plan: "foo", 
          metadata: metadata, 
          start: Time.new(2014,1,1)
        )
        assert_equal BoffinIO::Subscription, subscription.class
        plan = subscription.plan
        assert_equal BoffinIO::Plan, plan.class
        assert_equal "foo", plan.slug
        assert_equal "heroku",subscription.metadata[:provider]
      end
    end
  end
  
  def test_it_creates_one_subscription
    VCR.use_cassette('one_customer') do
      customer = BoffinIO::Customer.retrieve("1398")
      VCR.use_cassette('create_subscription') do
        metadata = {:provider => "heroku"}
        subscription = customer.create_subscription(
          plan: "foo", 
          metadata: metadata, 
          start: Time.new(2014,1,1)
        )
        assert_equal BoffinIO::Subscription, subscription.class
        plan = subscription.plan
        assert_equal BoffinIO::Plan, plan.class
        assert_equal "foo", plan.slug
        assert_equal "heroku",subscription.metadata[:provider]
      end
    end
  end

  def test_it_deletes_subscriptions
    VCR.use_cassette('one_customer') do
      customer = BoffinIO::Customer.retrieve("1398")
      VCR.use_cassette('cancel_subscription') do
        subscription = customer.cancel_subscription
        assert_equal BoffinIO::Subscription, subscription.class
        refute_nil subscription.canceled_at
      end
    end
  end

  def test_it_updates_subscriptions
    VCR.use_cassette('one_customer') do
      customer = BoffinIO::Customer.retrieve("1398")
      VCR.use_cassette('update_subscription') do
        metadata = {:provider => "heroku"}
        subscription = customer.update_subscription(:plan => "test", :metadata => metadata)
        assert_equal BoffinIO::Subscription, subscription.class
        plan = subscription.plan
        assert_equal BoffinIO::Plan, plan.class
        assert_equal "test", plan.slug
        assert_equal "heroku",subscription.metadata[:provider]
      end
    end
  end

  def test_it_lists_subscriptions
    VCR.use_cassette('one_customer') do
      customer = BoffinIO::Customer.retrieve("1398")
      VCR.use_cassette('customer_subscriptions', :record => :new_episodes) do
        subscriptions =  customer.subscriptions.all
        sub1 = subscriptions.first
        assert_equal BoffinIO::Subscription, sub1.class
      end
    end
  end

  def test_it_updates_a_named_subscription
    VCR.use_cassette('one_customer') do
      customer = BoffinIO::Customer.retrieve("1398")
      VCR.use_cassette('customer_subscriptions', :record => :new_episodes) do
        subscriptions =  customer.subscriptions.all
        sub1 = subscriptions.first
        sub1.metadata = {:country => "gb"}
        VCR.use_cassette('update_named_subscription', :record => :new_episodes) do
          result = sub1.save
          assert_equal "gb",result.metadata[:country]
        end
      end
    end
  end

end