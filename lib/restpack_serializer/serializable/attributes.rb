module RestPack::Serializer::Attributes
  extend ActiveSupport::Concern

  def default_href
    "#{self.class.href_prefix}/#{self.class.key}/#{@model.to_param}"
  end

  module ClassMethods
    def serializable_attributes
      @serializable_attributes
    end

    def attributes(*attrs)
      attrs.each { |attr| attribute attr }
    end

    def optional(*attrs)
      attrs.each { |attr| optional_attribute attr }
    end

    def transform(attrs = [], transform_lambda)
      attrs.each { |attr| transform_attribute(attr, transform_lambda) }
    end

    def transform_attribute(name, transform_lambda, options = {})
      add_to_serializable(name, options)

      define_method name do
        transform_lambda.call(name, @model)
      end

      define_include_method name
    end

    def attribute(name, options={})
      add_to_serializable(name, options)
      define_attribute_method name
      define_include_method name
    end

    def optional_attribute(name, options={})
      add_to_serializable(name, options)
      define_attribute_method name
      define_optional_include_method name
    end

    def define_attribute_method(name)
      unless method_defined?(name)
        define_method name do
          value = self.default_href if name == :href
          if @model.is_a?(Hash)
            value ||= @model[name] || @model[name.to_s]
          else
            value ||= @model.send(name)
          end
          value = value.to_s if name == :id
          value
        end
      end
    end

    def define_optional_include_method(name)
      define_include_method(name, false)
    end

    def define_include_method(name, include_by_default=true)
      method = "include_#{name}?".to_sym

      unless method_defined?(method)
        if include_by_default
          define_method method do
            @context[method].nil? || @context[method]
          end
        else
          define_method method do
            @context[method].present?
          end
        end
      end
    end

    def add_to_serializable(name, options = {})
      options[:key] ||= name.to_sym

      @serializable_attributes ||= {}
      @serializable_attributes[options[:key]] = name
    end
  end
end
