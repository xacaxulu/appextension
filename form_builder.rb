module AppExtension
  module RailsExtensions
    module FormBuilder

      def self.__required_label_args(method, text = nil, options = {})
        text = (text.blank? ? nil : text.to_s) || method.to_s.humanize
        options.merge!(:class => 'required')
        [method, %Q[#{text}<span class="red">*</span>].html_safe, options]
      end

      def required_label(method, text = nil, options = {})
        tag_value = options.delete("value")
        content = text.try_method(:to_s).presence || tag_value.try_method(:to_s).presence
        if content.blank?
          keys = [ "helpers.label.#{object_name}.#{method}", "activerecord.attributes.#{object_name}.#{method}", "#{method}"]
          content = keys.map{|key| I18n.t(key, :default => '')}.select(&:present?).first || ''
        end 
        label *FormBuilder::__required_label_args(method, content, options)
      end
    end

    module FormTagHelper
      def required_label_tag(name, text = nil, options = {})
        label_tag *FormBuilder::__required_label_args(name, text, options)
      end
    end

    module ErrorMessagesHelper
      # ORIGINALLY COPIED FROM THE DYNAMIC_FORM GEM
      # Returns a string containing the error message attached to the +method+ on the +object+ if one exists.
      # This error message is wrapped in a <tt>DIV</tt> tag by default or with <tt>:html_tag</tt> if specified,
      # which can be extended to include a <tt>:prepend_text</tt> and/or <tt>:append_text</tt> (to properly explain
      # the error), and a <tt>:css_class</tt> to style it accordingly. +object+ should either be the name of an
      # instance variable or the actual object. The method can be passed in either as a string or a symbol.
      # As an example, let's say you have a model <tt>@post</tt> that has an error message on the +title+ attribute:
      #
      #   <%= error_message_on "post", "title" %>
      #   # => <div class="formError">can't be empty</div>
      #
      #   <%= error_message_on @post, :title %>
      #   # => <div class="formError">can't be empty</div>
      #
      #   <%= error_message_on "post", "title",
      #       :prepend_text => "Title simply ",
      #       :append_text => " (or it won't work).",
      #       :html_tag => "span",
      #       :css_class => "inputError" %>
      #   # => <span class="inputError">Title simply can't be empty (or it won't work).</span>
      def error_message_on(object, method, *args)
        options = args.extract_options!
        options.reverse_merge!(:prepend_text => '', :append_text => '', :html_tag => 'div', :css_class => 'formError')

        object = convert_to_model(object)

        if (obj = (object.respond_to?(:errors) ? object : instance_variable_get("@#{object}"))) &&
          (errors = obj.errors[method]).presence
          content_tag(options[:html_tag],
            (options[:prepend_text].html_safe << errors.first).safe_concat(options[:append_text]),
            :class => options[:css_class]
          )
        else
          ''
        end
      end 

      # ORIGINALLY COPIED FROM THE DYNAMIC_FORM GEM
      # MODIFICATIONS INCLUDE ALLOWING HTML MARKUP WITHIN THE ERROR MESSAGES AND REMOVING DEPRECATED CODE
      #
      # Returns a string with a <tt>DIV</tt> containing all of the error messages for the objects located as instance variables by the names
      # given.  If more than one object is specified, the errors for the objects are displayed in the order that the object names are
      # provided.
      #
      # This <tt>DIV</tt> can be tailored by the following options:
      #
      # * <tt>:header_tag</tt> - Used for the header of the error div (default: "h2").
      # * <tt>:id</tt> - The id of the error div (default: "error_explanation").
      # * <tt>:class</tt> - The class of the error div (default: "error_explanation").
      # * <tt>:object</tt> - The object (or array of objects) for which to display errors,
      #   if you need to escape the instance variable convention.
      # * <tt>:object_name</tt> - The object name to use in the header, or any text that you prefer.
      #   If <tt>:object_name</tt> is not set, the name of the first object will be used.
      # * <tt>:header_message</tt> - The message in the header of the error div.  Pass +nil+
      #   or an empty string to avoid the header message altogether. (Default: "X errors
      #   prohibited this object from being saved").
      # * <tt>:message</tt> - The explanation message after the header message and before
      #   the error list.  Pass +nil+ or an empty string to avoid the explanation message
      #   altogether. (Default: "There were problems with the following fields:").
      #
      # To specify the display for one object, you simply provide its name as a parameter.
      # For example, for the <tt>@user</tt> model:
      #
      #   error_messages_for 'user'
      #
      # You can also supply an object:
      #
      #   error_messages_for @user
      #
      # This will use the last part of the model name in the presentation. For instance, if
      # this is a MyKlass::User object, this will use "user" as the name in the String. This
      # is taken from MyKlass::User.model_name.human, which can be overridden.
      #
      # To specify more than one object, you simply list them; optionally, you can add an extra <tt>:object_name</tt> parameter, which
      # will be the name used in the header message:
      #
      #   error_messages_for 'user_common', 'user', :object_name => 'user'
      #
      # You can also use a number of objects, which will have the same naming semantics
      # as a single object.
      #
      #   error_messages_for @user, @post
      #
      # If the objects cannot be located as instance variables, you can add an extra <tt>:object</tt> parameter which gives the actual
      # object (or array of objects to use):
      #
      #   error_messages_for 'user', :object => @question.user
      #
      # NOTE: This is a pre-packaged presentation of the errors with embedded strings and a certain HTML structure. If what
      # you need is significantly different from the default presentation, it makes plenty of sense to access the <tt>object.errors</tt>
      # instance yourself and set it up. View the source of this method to see how easy it is.
      def error_messages_for(*params)
        options = params.extract_options!.symbolize_keys

        objects = Array.wrap(options.delete(:object) || params).map do |object|
          object = instance_variable_get("@#{object}") unless object.respond_to?(:to_model)
          object = convert_to_model(object)

          if object.class.respond_to?(:model_name)
            options[:object_name] ||= object.class.model_name.human.downcase
          end

          object
        end

        objects.compact!
        count = objects.inject(0) {|sum, object| sum + object.errors.count }

        unless count.zero?
          html = {}
          [:id, :class].each do |key|
            if options.include?(key)
              value = options[key]
              html[key] = value unless value.blank?
            else
              html[key] = 'error_explanation'
            end
          end
          options[:object_name] ||= params.first

          I18n.with_options :locale => options[:locale], :scope => [:activerecord, :errors, :template] do |locale|
            header_message = if options.include?(:header_message)
              options[:header_message]
            else
              locale.t :header, :count => count, :model => options[:object_name].to_s.gsub('_', ' ')
            end

            message = options.include?(:message) ? options[:message] : locale.t(:body)

            error_messages = objects.sum do |object|
              object.errors.full_messages.map do |msg|
                content_tag(:li, sanitize(msg).html_safe)
              end
            end.join

            contents = ''
            contents << content_tag(options[:header_tag] || :h2, header_message) unless header_message.blank?
            contents << content_tag(:p, message) unless message.blank?
            contents << content_tag(:ul, error_messages.html_safe)

            content_tag(:div, contents.html_safe, html)
          end
        else
          ''
        end
      end
    end
  end
end

ActionView::Helpers::FormBuilder.send(:include, Jade::RailsExtensions::FormBuilder)
ActionView::Base.send(:include, Jade::RailsExtensions::FormTagHelper)
ActionView::Base.send(:include, Jade::RailsExtensions::ErrorMessagesHelper)module Jade
  module RailsExtensions
    module FormBuilder

      def self.__required_label_args(method, text = nil, options = {})
        text = (text.blank? ? nil : text.to_s) || method.to_s.humanize
        options.merge!(:class => 'required')
        [method, %Q[#{text}<span class="red">*</span>].html_safe, options]
      end

      def required_label(method, text = nil, options = {})
        tag_value = options.delete("value")
        content = text.try_method(:to_s).presence || tag_value.try_method(:to_s).presence
        if content.blank?
          keys = [ "helpers.label.#{object_name}.#{method}", "activerecord.attributes.#{object_name}.#{method}", "#{method}"]
          content = keys.map{|key| I18n.t(key, :default => '')}.select(&:present?).first || ''
        end 
        label *FormBuilder::__required_label_args(method, content, options)
      end
    end

    module FormTagHelper
      def required_label_tag(name, text = nil, options = {})
        label_tag *FormBuilder::__required_label_args(name, text, options)
      end
    end

    module ErrorMessagesHelper
      # ORIGINALLY COPIED FROM THE DYNAMIC_FORM GEM
      # Returns a string containing the error message attached to the +method+ on the +object+ if one exists.
      # This error message is wrapped in a <tt>DIV</tt> tag by default or with <tt>:html_tag</tt> if specified,
      # which can be extended to include a <tt>:prepend_text</tt> and/or <tt>:append_text</tt> (to properly explain
      # the error), and a <tt>:css_class</tt> to style it accordingly. +object+ should either be the name of an
      # instance variable or the actual object. The method can be passed in either as a string or a symbol.
      # As an example, let's say you have a model <tt>@post</tt> that has an error message on the +title+ attribute:
      #
      #   <%= error_message_on "post", "title" %>
      #   # => <div class="formError">can't be empty</div>
      #
      #   <%= error_message_on @post, :title %>
      #   # => <div class="formError">can't be empty</div>
      #
      #   <%= error_message_on "post", "title",
      #       :prepend_text => "Title simply ",
      #       :append_text => " (or it won't work).",
      #       :html_tag => "span",
      #       :css_class => "inputError" %>
      #   # => <span class="inputError">Title simply can't be empty (or it won't work).</span>
      def error_message_on(object, method, *args)
        options = args.extract_options!
        options.reverse_merge!(:prepend_text => '', :append_text => '', :html_tag => 'div', :css_class => 'formError')

        object = convert_to_model(object)

        if (obj = (object.respond_to?(:errors) ? object : instance_variable_get("@#{object}"))) &&
          (errors = obj.errors[method]).presence
          content_tag(options[:html_tag],
            (options[:prepend_text].html_safe << errors.first).safe_concat(options[:append_text]),
            :class => options[:css_class]
          )
        else
          ''
        end
      end 

      # ORIGINALLY COPIED FROM THE DYNAMIC_FORM GEM
      # MODIFICATIONS INCLUDE ALLOWING HTML MARKUP WITHIN THE ERROR MESSAGES AND REMOVING DEPRECATED CODE
      #
      # Returns a string with a <tt>DIV</tt> containing all of the error messages for the objects located as instance variables by the names
      # given.  If more than one object is specified, the errors for the objects are displayed in the order that the object names are
      # provided.
      #
      # This <tt>DIV</tt> can be tailored by the following options:
      #
      # * <tt>:header_tag</tt> - Used for the header of the error div (default: "h2").
      # * <tt>:id</tt> - The id of the error div (default: "error_explanation").
      # * <tt>:class</tt> - The class of the error div (default: "error_explanation").
      # * <tt>:object</tt> - The object (or array of objects) for which to display errors,
      #   if you need to escape the instance variable convention.
      # * <tt>:object_name</tt> - The object name to use in the header, or any text that you prefer.
      #   If <tt>:object_name</tt> is not set, the name of the first object will be used.
      # * <tt>:header_message</tt> - The message in the header of the error div.  Pass +nil+
      #   or an empty string to avoid the header message altogether. (Default: "X errors
      #   prohibited this object from being saved").
      # * <tt>:message</tt> - The explanation message after the header message and before
      #   the error list.  Pass +nil+ or an empty string to avoid the explanation message
      #   altogether. (Default: "There were problems with the following fields:").
      #
      # To specify the display for one object, you simply provide its name as a parameter.
      # For example, for the <tt>@user</tt> model:
      #
      #   error_messages_for 'user'
      #
      # You can also supply an object:
      #
      #   error_messages_for @user
      #
      # This will use the last part of the model name in the presentation. For instance, if
      # this is a MyKlass::User object, this will use "user" as the name in the String. This
      # is taken from MyKlass::User.model_name.human, which can be overridden.
      #
      # To specify more than one object, you simply list them; optionally, you can add an extra <tt>:object_name</tt> parameter, which
      # will be the name used in the header message:
      #
      #   error_messages_for 'user_common', 'user', :object_name => 'user'
      #
      # You can also use a number of objects, which will have the same naming semantics
      # as a single object.
      #
      #   error_messages_for @user, @post
      #
      # If the objects cannot be located as instance variables, you can add an extra <tt>:object</tt> parameter which gives the actual
      # object (or array of objects to use):
      #
      #   error_messages_for 'user', :object => @question.user
      #
      # NOTE: This is a pre-packaged presentation of the errors with embedded strings and a certain HTML structure. If what
      # you need is significantly different from the default presentation, it makes plenty of sense to access the <tt>object.errors</tt>
      # instance yourself and set it up. View the source of this method to see how easy it is.
      def error_messages_for(*params)
        options = params.extract_options!.symbolize_keys

        objects = Array.wrap(options.delete(:object) || params).map do |object|
          object = instance_variable_get("@#{object}") unless object.respond_to?(:to_model)
          object = convert_to_model(object)

          if object.class.respond_to?(:model_name)
            options[:object_name] ||= object.class.model_name.human.downcase
          end

          object
        end

        objects.compact!
        count = objects.inject(0) {|sum, object| sum + object.errors.count }

        unless count.zero?
          html = {}
          [:id, :class].each do |key|
            if options.include?(key)
              value = options[key]
              html[key] = value unless value.blank?
            else
              html[key] = 'error_explanation'
            end
          end
          options[:object_name] ||= params.first

          I18n.with_options :locale => options[:locale], :scope => [:activerecord, :errors, :template] do |locale|
            header_message = if options.include?(:header_message)
              options[:header_message]
            else
              locale.t :header, :count => count, :model => options[:object_name].to_s.gsub('_', ' ')
            end

            message = options.include?(:message) ? options[:message] : locale.t(:body)

            error_messages = objects.sum do |object|
              object.errors.full_messages.map do |msg|
                content_tag(:li, sanitize(msg).html_safe)
              end
            end.join

            contents = ''
            contents << content_tag(options[:header_tag] || :h2, header_message) unless header_message.blank?
            contents << content_tag(:p, message) unless message.blank?
            contents << content_tag(:ul, error_messages.html_safe)

            content_tag(:div, contents.html_safe, html)
          end
        else
          ''
        end
      end
    end
  end
end

ActionView::Helpers::FormBuilder.send(:include, AppExtension::RailsExtensions::FormBuilder)
ActionView::Base.send(:include, AppExtension::RailsExtensions::FormTagHelper)
ActionView::Base.send(:include, AppExtension::RailsExtensions::ErrorMessagesHelper)
