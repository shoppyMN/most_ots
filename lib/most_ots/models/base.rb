module MostOts
  class Base

    def initialize(data)
      @data = data
    end

    def method_missing(method_name, *args, &block)
      if @data.key?(method_name)
        @data[method_name]
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private = false)
      @data.key?(method_name)
    end
  end
end
