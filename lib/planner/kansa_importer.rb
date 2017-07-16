

module Planner
  module KansaImporter

    extend self
    
    def find_kansa_person(kansa_person)
      legal_name = kansa_person['legal_name']
      public_first_name = kansa_person['public_first_name']
      public_last_name = kansa_person['public_last_name']
      email= kansa_person['email']

      # if last name is empty then get it from the legal_name
      if public_last_name.blank?
        if !public_first_name.blank?
          public_last_name = legal_name
          public_last_name.slice!(public_first_name)
          public_last_name.strip!
        end
      end
      
      person = find_person(
        first_name: public_first_name,
        last_name: public_last_name,
        legal_name: legal_name
        )
        
      person
    end
    
    def import_person(kansa_person)
      legal_name = kansa_person['legal_name']
      public_first_name = kansa_person['public_first_name']
      public_last_name = kansa_person['public_last_name']
      email= kansa_person['email']
      
      person = find_kansa_person(kansa_person)
        
      if !person && !public_last_name.blank?
        # The public name may be a pseudonymn
        # compare with the legal name to make sure
        if legal_name.include?(public_last_name.strip)
          first_name = public_first_name
          if first_name.blank?
            first_name = legal_name
            first_name.slice!(public_last_name)
            first_name.strip!
          end
          person = create_person(first_name, public_last_name)
        end
      end
          
      if !person
        name_parts = legal_name.split
        first_name_candidate = name_parts[0..(name_parts.size-2)].join(" ").strip
        last_name_candidate = name_parts.last.strip
        person = create_person(first_name_candidate, last_name_candidate)
        
        if !public_last_name.blank? # create pseudonymn
          pseudonymn = Pseudonym.create({
            person_id: person.id,
            first_name: public_first_name,
            last_name: public_last_name
            })
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
      person.save
    end

    # Try to find the person in the DB based on their name
    def find_person(first_name: nil, last_name: nil, legal_name: nil)
      person = nil

      # puts "** first and last"
      # puts first_name
      # puts last_name

      if !first_name.blank? && !last_name.blank?
        person = Person.find_by({
          first_name: first_name.strip,
          last_name: last_name.strip
        })
      end
      
      if !person && !legal_name.blank?
        name_parts = legal_name.split
        first_name_candidate = name_parts.first
        last_name_candidate = name_parts.last
        
        # puts "** first and last candidate"
        # puts first_name_candidate
        # puts last_name_candidate

        person = Person.find_by({
          first_name: first_name_candidate.strip,
          last_name: last_name_candidate.strip
        }) if !first_name_candidate.blank? && !last_name_candidate.blank?
        
        if !person
          last_name_candidate = name_parts[1..name_parts.size].join(" ").strip
          person = Person.find_by({
            first_name: first_name_candidate.strip,
            last_name: last_name_candidate.strip
          })
        end

        if !person
          first_name_candidate = name_parts[0..(name_parts.size-1)].join(" ").strip
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
