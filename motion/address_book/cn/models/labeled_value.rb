module AddressBook
  module CN
    class LabeledValue
      INITIALIZATION_ERROR =
        "LabeledValue must be initialized with an CNLabeledValue or Hash"
      KNOWN_VALUE_TYPES = [
        :address,
        :im_address,
        :phone,
        :relation,
        :simple,
        :social_profile
      ]
      LABEL_MAP = {
        # Generic Labels
        :work  => "_$!<Work>!$_",  # CNLabelWork
        :home  => "_$!<Home>!$_",  # CNLabelHome
        :other => "_$!<Other>!$_", # CNLabelOther
        # Email Labels
        :icloud => "iCloud", # CNLabelEmailiCloud
        # URL Labels
        :home_page => "_$!<HomePage>!$_", # CNLabelURLAddressHomePage
        # Date Labels
        :anniversary => "_$!<Anniversary>!$_", # CNLabelDateAnniversary
        # Phone Number Labels
        :mobile    => "_$!<Mobile>!$_",   # CNLabelPhoneNumberMobile
        :iphone    => "iPhone",           # CNLabelPhoneNumberiPhone
        :main      => "_$!<Main>!$_",     # CNLabelPhoneNumberMain
        :home_fax  => "_$!<HomeFAX>!$_",  # CNLabelPhoneNumberHomeFax
        :work_fax  => "_$!<WorkFAX>!$_",  # CNLabelPhoneNumberWorkFax
        :other_fax => "_$!<OtherFAX>!$_", # CNLabelPhoneNumberOtherFax
        :pager     => "_$!<Pager>!$_",    # CNLabelPhoneNumberPager
        # Relation Labels
        :father    => "_$!<Father>!$_",    # CNLabelContactRelationFather
        :mother    => "_$!<Mother>!$_",    # CNLabelContactRelationMother
        :parent    => "_$!<Parent>!$_",    # CNLabelContactRelationParent
        :brother   => "_$!<Brother>!$_",   # CNLabelContactRelationBrother
        :sister    => "_$!<Sister>!$_",    # CNLabelContactRelationSister
        :child     => "_$!<Child>!$_",     # CNLabelContactRelationChild
        :friend    => "_$!<Friend>!$_",    # CNLabelContactRelationFriend
        :spouse    => "_$!<Spouse>!$_",    # CNLabelContactRelationSpouse
        :partner   => "_$!<Partner>!$_",   # CNLabelContactRelationPartner
        :assistant => "_$!<Assistant>!$_", # CNLabelContactRelationAssistant
        :manager   => "_$!<Manager>!$_"    # CNLabelContactRelationManager
      }

      attr_reader(
        :label,
        :value
      )

      def initialize(hash_or_record)
        # Assign the local variables as appropriate
        if hash_or_record.is_a?(CNLabeledValue)
          parse_record!(hash_or_record)
        elsif hash_or_record.is_a?(Hash)
          parse_hash!(hash_or_record)
        else
          raise(ArugmentError, INITIALIZATION_ERROR)
        end

        self
      end

      def label=(new_value)
        @label = new_value
        @native_ref.label = LABEL_MAP[new_value]
      end

      def value=(new_value)
        @value = new_value
        @native_ref.value = new_value
      end

      def values
        { label: @label }.merge(@value)
      end
      alias :as_hash :values
      alias :to_ary :values
      alias :to_h :values

      private

      def ruby_hash_to_cn_keys(hash_value)
        case @value_type
        when :phone
          { number: hash_value[:number] }
        when :address
          {
            street: hash_value[:street],
            city: hash_value[:city],
            state: hash_value[:state],
            postalCode: hash_value[:postal_code],
            country: hash_value[:country],
            ISOCountryCode: hash_value[:iso_country_code],
          }
        when :relation
          { name: hash_value[:name] }
        when :im_address
          {
            service: hash_value[:service],
            username: hash_value[:username]
          }
        when :social_profile
          {
            service: hash_value[:service],
            urlString: hash_value[:url_string],
            userIdentifier: hash_value[:user_identifier],
            username: hash_value[:username]
          }
        when :simple
          { value: hash_value[:value] }
        end
      end

      def localized_label(str)
        LABEL_MAP[str] || str
      end

      def parse_record!(cn_record)
        @native_ref = cn_record
        @label = LABEL_MAP.invert[cn_record.label]
        parse_record_value!(cn_record.value)
      end

      def parse_record_value!(cn_value)
        case cn_value
        when CNPhoneNumber
          @value_type = :phone
          @value = { number: cn_value.stringValue }
        when CNPostalAddress
          @value_type = :address
          @value = {
            street: cn_value.street,
            city: cn_value.city,
            state: cn_value.state,
            postal_code: cn_value.postalCode,
            country: cn_value.country,
            iso_country_code: cn_value.ISOCountryCode,
          }
        when CNContactRelation
          @value_type = :relation
          @value = { name: cn_value.name }
        when CNInstantMessageAddress
          @value_type = :im_address
          @value = { service: cn_value.service, username: cn_value.username }
        when CNSocialProfile
          @value_type = :social_profile
          @value = {
            service: cn_value.service,
            url_string: cn_value.urlString,
            user_identifier: cn_value.userIdentifier,
            username: cn_value.username
          }
        else
          @value_type = :simple
          @value = { value: cn_value }
        end
      end

      def parse_hash!(hash)
        value_type = hash[:value_type].to_sym
        unless KNOWN_VALUE_TYPES.include?(value_type)
          raise(ArgumentError, "Invalid value type")
        end
        raise(ArgumentError, "No value given") unless hash[:value]

        @label = hash.delete :label
        @values = hash
        @value_type = value_type

        method =
          case @value_type
          when :phone then :new_phone
          when :address then :new_address
          when :relation then :new_relation
          when :im_address then :new_im_address
          when :social_profile then :new_social_profile
          when :simple then :new_value
          end

        @native_ref = Accessors::LabeledValue.send(method,
          @label, ruby_hash_to_cn_keys(hash[:value])
        )
      end
    end
  end
end
