module TestHelpers
  def login_as(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
  end

  def freeze_time(&block)
    travel_to(Time.current, &block)
  end
end

RSpec.configure do |config|
  config.include TestHelpers
  config.include ActiveSupport::Testing::TimeHelpers
end
