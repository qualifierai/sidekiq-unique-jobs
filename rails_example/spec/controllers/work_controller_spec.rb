require 'rails_helper'

describe WorkController do
  context 'with real redis' do
    before do
      SidekiqUniqueJobs.configure do |config|
        config.redis_test_mode = :redis
      end
      Sidekiq::Worker.clear_all
      Sidekiq.redis(&:flushdb)
    end

    describe 'GET /work/duplicate_simple' do
      context 'when test mode is fake', sidekiq: :fake do
        specify do
          expect { get :duplicate_simple }
            .to change { SimpleWorker.jobs.size }
            .from(0)
            .to(1)
        end
      end

      context 'when test mode is disabled', sidekiq: :disable do
        specify do
          get :duplicate_simple
          Sidekiq.redis do |c|
            expect(c.llen('queue:default')).to eq(1)
            expect(c.keys).to include('uniquejobs:83bda9f47b05071ffcb35cbb59e1fada')
          end
        end
      end

      context 'when test mode is inline', sidekiq: :inline do
        specify do
          expect_any_instance_of(SimpleWorker).to receive(:perform).with(1).exactly(:once)
          get :duplicate_simple
        end
      end
    end

    describe 'GET /work/duplicate_nested' do
      context 'when test mode is fake', sidekiq: :fake do
        specify do
          expect { get :duplicate_nested }
            .to change { SpawnSimpleWorker.jobs.size }
            .from(0)
            .to(4)
        end
      end

      context 'when test mode is disabled', sidekiq: :disable do
        specify do
          get :duplicate_nested

          Sidekiq.redis do |c|
            expect(c.llen('queue:default')).to eq(4)
            expect(c.keys).not_to include('uniquejobs:83bda9f47b05071ffcb35cbb59e1fada')
          end
        end
      end

      context 'when test mode is inline', sidekiq: :inline do
        specify do
          expect_any_instance_of(SimpleWorker).to receive(:perform).with(1).exactly(:once).and_call_original
          get :duplicate_nested

          Sidekiq.redis do |c|
            expect(c.llen('queue:default')).to eq(1)
            expect(c.keys).to include('uniquejobs:83bda9f47b05071ffcb35cbb59e1fada')
          end
        end
      end
    end
  end

  context 'with mock_redis' do
    before do
      SidekiqUniqueJobs.configure do |config|
        config.redis_test_mode = :mock
      end
      allow(Redis).to receive(:new).and_return(MockRedis.new)
    end
    describe 'GET /work/duplicate_simple' do
      context 'when test mode is fake', sidekiq: :fake do
        specify do
          expect { get :duplicate_simple }
            .to change { SimpleWorker.jobs.size }
            .from(0)
            .to(1)
        end
      end

      context 'when test mode is disabled', sidekiq: :disable do
        specify do
          get :duplicate_simple
          Sidekiq.redis do |c|
            expect(c.llen('queue:default')).to eq(1)
            expect(c.keys).to include('uniquejobs:83bda9f47b05071ffcb35cbb59e1fada')
          end
        end
      end

      context 'when test mode is inline', sidekiq: :inline do
        specify do
          expect_any_instance_of(SimpleWorker).to receive(:perform).with(1).exactly(:once)
          get :duplicate_simple
        end
      end
    end

    describe 'GET /work/duplicate_nested' do
      context 'when test mode is fake', sidekiq: :fake do
        specify do
          expect { get :duplicate_nested }
            .to change { SpawnSimpleWorker.jobs.size }
            .from(0)
            .to(4)
        end
      end

      context 'when test mode is disabled', sidekiq: :disable do
        specify do
          get :duplicate_nested

          Sidekiq.redis do |c|
            expect(c.llen('queue:default')).to eq(5)
            expect(c.keys).not_to include('uniquejobs:83bda9f47b05071ffcb35cbb59e1fada')
          end
        end
      end

      context 'when test mode is inline', sidekiq: :inline do
        specify do
          expect_any_instance_of(SimpleWorker).to receive(:perform).with(1).exactly(:once).and_call_original
          get :duplicate_nested

          Sidekiq.redis do |c|
            expect(c.llen('queue:default')).to eq(1)
            expect(c.keys).to include('uniquejobs:83bda9f47b05071ffcb35cbb59e1fada')
          end
        end
      end
    end
  end
end
