

module Planner
  module KansaImporter

    extend self
    
    def import_person(kansa_person)
      legal_name = kansa_person['legal_name']
      public_first_name = kansa_person['public_first_name']
      public_last_name = kansa_person['public_last_name']
      email= kansa_person['email']

      # if last name is empty then get it from the legal_name
      if public_last_name.blank? && public_first_name
        public_last_name = legal_name
        public_last_name.slice!(public_first_name)
        public_last_name.strip!
      end
      
      person = find_person(
        first_name: public_first_name,
        last_name: public_last_name,
        legal_name: legal_name
        )
        
      if !person
        if public_last_name
          first_name = public_first_name
          if !first_name
            first_name = legal_name
            first_name.slice!(public_last_name)
            first_name.strip!
          end
          person = create_person(first_name, public_last_name)
        else
          name_parts = legal_name.split
          first_name_candidate = name_parts[0..(name_parts.size-2)].join(" ").strip
          last_name_candidate = name_parts.last
          person = create_person(first_name_candidate, last_name_candidate)
        end
      end
      
      update_email(person, email)
      
      person
    end
    
    def create_member_details(person, kansa_person)
      if !person.registrationDetail
        registrationDetail = RegistrationDetail.create({
          person_id: person.id,
          registration_number: kansa_person['member_number'],
          registration_type: kansa_person['membership'],
          registered: true,
          can_share: false
        })
      end
    end

    def create_postal_address(person, kansa_person)
      address = person.getDefaultPostalAddress
      
      if address
        return if address.city == kansa_person['city'] &&
          address.state == kansa_person['state'] &&
          address.country == kansa_person['country']
        
        address.isdefault = false
        address.save!
      end

      addr = person.postal_addresses.new(
        :city => kansa_person['city'], 
        :state => kansa_person['state'],
        :country => kansa_person['country'], 
        :isdefault => true 
      )
      
      addr.save(validate: false)
    end

    # Try to find the person in the DB based on their name
    def find_person(first_name: nil, last_name: nil, legal_name: nil)
      person = nil

      if first_name && last_name
        person = Person.find_by({
          first_name: first_name.strip,
          last_name: last_name.strip
        })
      else
        name_parts = legal_name.split
        first_name_candidate = name_parts.first
        last_name_candidate = name_parts.last

        person = Person.find_by({
          first_name: first_name_candidate.strip,
          last_name: last_name_candidate.strip
        })
        
        if !person
          last_name_candidate = name_parts[1..name_parts.size].join(" ").strip
          person = Person.find_by({
            first_name: first_name_candidate.strip,
            last_name: last_name_candidate.strip
          })
        end
      end
      
      person
    end

    def create_person(first_name, last_name)
      person = Person.create({
        first_name: first_name.strip,
        last_name: last_name.strip
      })
    end
    
    def update_email(person, email)
      def_email = person.getDefaultEmail() ? person.getDefaultEmail().email.strip : nil
      person.updateDefaultEmail(email.strip) if email && (def_email != email.strip)
    end

  end
end
