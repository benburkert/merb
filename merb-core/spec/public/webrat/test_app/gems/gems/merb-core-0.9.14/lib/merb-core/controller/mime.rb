module Merb
  class << self

    
    # Returns a hash of the available mime types. 
    #
    # ==== Returns
    # Hash{Symbol => Hash{Symbol => Object}}:: The available mime types.
    #
    # ==== Notes
    # Each entry corresponds to a call to add_mime_type, having the mime type key (:html, :xml, :json, etc.)
    # as the key and a hash containing the following entries:
    #   :accepts           # the mime types that will be recognized by this entry
    #   :transform_method  # the method called on an object to convert it to content of this type (such as to_json)
    #   :content_type      # the value set to the "Content-Type" HTTP header when this mime is sent in a response
    #   :response_headers  # sent in a response using this content type
    #   :default_quality   # the scale factor used in describing content type preference
    #   :response_block    # the block to be called with the controller when a request responds to this mime type
    #
    # @api public
    def available_mime_types
      ResponderMixin::TYPES
    end

    # ==== Returns
    # Hash{String => Symbol}:: 
    #   A hash mapping Content-Type values to the mime type key of the appropriate entry in #available_mime_types
    #
    # @api public
    def available_accepts
      ResponderMixin::MIMES
    end

    # Any specific outgoing headers should be included here.  These are not
    # the content-type header but anything in addition to it.
    # +transform_method+ should be set to a symbol of the method used to
    # transform a resource into this mime type.
    # For example for the :xml mime type an object might be transformed by
    # calling :to_xml, or for the :js mime type, :to_json.
    # If there is no transform method, use nil.
    #
    # ==== Autogenerated Methods
    # Adding a mime-type adds a render_type method that sets the content
    # type and calls render.
    # 
    # By default this does: def render_all, def render_yaml, def render_text,
    # def render_html, def render_xml, def render_js, and def render_yaml
    #
    # ==== Parameters
    # key<Symbol>:: The name of the mime-type. This is used by the provides API
    # transform_method<~to_s>:: 
    #   The associated method to call on objects to convert them to the
    #   appropriate mime-type. For instance, :json would use :to_json as its
    #   transform_method.
    # mimes<Array[String]>::
    #   A list of possible values sent in the Accept header, such as text/html,
    #   that should be associated with this content-type.
    # new_response_headers<Hash>::
    #   The response headers to set for the the mime type. For example: 
    #   'Content-Type' => 'application/json; charset=utf-8'; As a shortcut for
    #   the common charset option, use :charset => 'utf-8', which will be
    #   correctly appended to the mimetype itself.
    # &block:: a block which recieves the current controller when the format
    #   is set (in the controller's #content_type method)
    #
    # ==== Returns
    # nil
    #
    # @api public
    def add_mime_type(key, transform_method, mimes, new_response_headers = {}, default_quality = 1, &block) 
      enforce!(key => Symbol, mimes => Array)
      
      content_type = new_response_headers["Content-Type"] || mimes.first
      
      if charset = new_response_headers.delete(:charset)
        content_type += "; charset=#{charset}"
      end
      
      ResponderMixin::TYPES.update(key => 
        {:accepts           => mimes, 
         :transform_method  => transform_method,
         :content_type      => content_type,
         :response_headers  => new_response_headers,
         :default_quality   => default_quality,
         :response_block    => block })

      mimes.each do |mime|
        ResponderMixin::MIMES.update(mime => key)
      end

      Merb::RenderMixin.class_eval <<-EOS, __FILE__, __LINE__
        def render_#{key}(thing = nil, opts = {})
          self.content_type = :#{key}
          render thing, opts
        end
      EOS
      
      nil
    end

    # Removes a MIME-type from the mime-type list.
    #
    # ==== Parameters
    # key<Symbol>:: The key that represents the mime-type to remove.
    #
    # ==== Returns
    # (Boolean, Hash{Symbol => Object}):: If it was present, the old specification of the MIME-type. Same structure
    #   as a value in Merb.available_mime_types. False if the key was not present.
    #
    # ==== Notes
    # :all is the key for */*; It can't be removed.
    #
    # @api public
    def remove_mime_type(key)
      return false if key == :all
      ResponderMixin::TYPES.delete(key)
    end

    # ==== Parameters
    # key<Symbol>:: The key that represents the mime-type.
    #
    # ==== Returns
    # Symbol:: The transform method for the mime type, e.g. :to_json.
    #
    # ==== Raises
    # ArgumentError:: The requested mime type is not valid.
    #
    # @api private
    def mime_transform_method(key)
      raise ArgumentError, ":#{key} is not a valid MIME-type" unless ResponderMixin::TYPES.key?(key)
      ResponderMixin::TYPES[key][:transform_method]
    end

  end
end
