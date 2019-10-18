module Api
  module V1x0
    class AuthenticationsController < ApplicationController
      def create
        render :json => "OK".to_json
      end
    end

    class RootController < ApplicationController
      def openapi
        render :json => {:things => "stuff"}.to_json
      end
    end

    class VmsController < ApplicationController
      def index
        render :json => {:things => "stuff"}.to_json
      end

      def show
        render :json => {:id => request_path_parts["primary_collection_id"]}.to_json
      end
    end

    class PersonsController < ApplicationController
      def create
        params_for_create
        render :json => "OK".to_json
      end

      def update
        params_for_update
        render :json => "OK".to_json
      end

      def index
        safe_params_for_list
        render :json => {:things => "stuff"}.to_json
      end
    end

    class ExtrasController < ApplicationController
      self.openapi_enabled = false

      def index
        safe_params_for_list
        render :json => "OK".to_json
      end
    end

    class ErrorsController < ApplicationController
      class SomethingHappened < StandardError; end

      def error
        raise StandardError, "something happened"
      end

      def error_nested
        raise ArgumentError, "something happened"
      rescue ArgumentError
        raise SomethingHappened, "something else happened"
      end
    end

    class GraphqlController < Api::V1::GraphqlController; end
    class SourcesController < Api::V1::SourcesController; end
    class SourceTypesController < Api::V1::SourceTypesController; end
  end
end
