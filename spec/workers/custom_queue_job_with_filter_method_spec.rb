# frozen_string_literal: true

RSpec.describe CustomQueueJobWithFilterMethod do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "queue" => :customqueue,
        "retry" => true,
        "lock" => :until_executed,
        "lock_args" => :args_filter,
      }
    end
  end
  it_behaves_like "a performing worker" do
    let(:args) { %w[one two] }
  end
end
