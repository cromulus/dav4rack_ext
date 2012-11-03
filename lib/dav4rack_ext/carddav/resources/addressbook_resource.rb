module DAV4Rack
  module Carddav
    
    class AddressbookResource < AddressbookBaseResource

      # The CardDAV spec requires that certain resources not be returned for an
      # allprop request.  It's nice to keep a list of all the properties we support
      # in the first place, so let's keep a separate list of the ones that need to
      # be explicitly requested.
      # ALL_PROPERTIES =  {
      #   'DAV:' => %w(
      #     current-user-privilege-set
      #     supported-report-set
      #   ),
      #   "urn:ietf:params:xml:ns:carddav" => %w(
      #     max-resource-size
      #     supported-address-data
      #   ),
      #   'http://calendarserver.org/ns/' => %w( getctag )
      # }

      # EXPLICIT_PROPERTIES = {
      #   'urn:ietf:params:xml:ns:carddav' => %w(
      #     addressbook-description
      #     max-resource-size
      #     supported-collation-set
      #     supported-address-data
      #   )
      # }
      
      define_properties('DAV:') do
        property('current-user-privilege-set') do
          privileges = %w(read write write-properties write-content read-acl read-current-user-privilege-set)
          s='<D:current-user-privilege-set xmlns:D="DAV:">%s</D:current-user-privilege-set>'

          privileges_aggregate = privileges.inject('') do |ret, priv|
            ret << '<D:privilege><%s /></privilege>' % priv
          end

          s % privileges_aggregate
        end
        
        property('supported-report-set') do
          reports = %w(addressbook-multiget)
          s = "<supported-report-set>%s</supported-report-set>"
          
          reports_aggregate = reports.inject('') do |ret, report|
            ret << "<report><C:%s xmlns:C='urn:ietf:params:xml:ns:carddav'/></report>" % report
          end
          
          s % reports_aggregate
        end
        
        property('resourcetype') do
          '<resourcetype><D:collection /><C:addressbook xmlns:C="urn:ietf:params:xml:ns:carddav"/></resourcetype>'
        end
        
        property('displayname') do
          @address_book.name
        end
        
        property('creationdate') do
          @address_book.created_at
        end

        # property('getetag') do
        #   '"None"'
        # end

        property('getlastmodified') do
          @address_book.updated_at
        end
        
      end
      
      
      define_properties('urn:ietf:params:xml:ns:carddav') do
        explicit do
          property('max-resource-size') do
            1024
          end
          
          property('supported-address-data') do
            <<-EOS
            <C:supported-address-data xmlns:C='urn:ietf:params:xml:ns:carddav'>
              <C:address-data-type content-type='text/vcard' version='3.0' />
            </C:supported-address-data>
            EOS
          end

          property('addressbook-description') do
            @address_book.name
          end
          
          property('max-resource-size') do
            
          end
          
          # TODO: fill this
          property('supported-collation-set') do
            
          end
          
          property('supported-address-data') do
            
          end
        end
        
      end
      
      
      define_properties('http://calendarserver.org/ns/') do
        property('getctag') do
          "<APPLE1:getctag xmlns:APPLE1='http://calendarserver.org/ns/'>#{@address_book.updated_at.to_i}</APPLE1:getctag>"
        end
      end

      def setup
        super
        @address_book = current_user.find_addressbook(@book_path)
        # @address_book = @addressbook_model_class.find_by_id_and_user_id(@book_path, current_user.id)
      end

      def exist?
        # Rails.logger.error "ABR::exist?(#{public_path})"
        return !@address_book.nil?
      end

      def collection?
        true
      end

      def children
        Logger.debug "ABR::children(#{public_path})"
        @address_book.contacts.collect do |c|
          Logger.debug "Trying to create this child (contact): #{c.uid.to_s}"
          child c.uid.to_s
        end
      end
      
      
      ## Properties follow in alphabetical order
      protected

      def content_type
        # Not the right type, oh well
        Mime::Type.lookup_by_extension(:dir).to_s
      end
      
    end
    
  end
end
