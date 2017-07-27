# desc "Explaining what the task does"
# task :planner_kansa do
#   # Task goes here
# end
require 'planner/kansa_importer'

# TODO - create a task that can be used to upodate the db
namespace :kansa do

  desc ""
  task :update_members => :environment do
    # Put the member import login in here
    # We also need to remember the last time this was run etc
    
    # can put matches into pending import ????
    org = ENV['ORG']
    conference = ENV['CONF']
    user = ENV['USER']
    key = ENV['KEY']
    
    current = nil

    Apartment::Tenant.switch!(org)
    tenant =  PlannerMulti::Conference.find_by_subsite conference
    
    if tenant
      ActsAsTenant.with_tenant(tenant) do
        Kansa::Client.instance.configure do |config|
          config.username = user
          config.key = key
        end  
        
        kansa_api = Kansa::Member.new

        # since to get members (from last run)
        since_date = nil
        jobInfo = JobInfo.where(:job_name => :kansa_import).first # should only be one entry
        since_date = jobInfo.last_run if jobInfo
        jobInfo = JobInfo.new if !jobInfo

        currentRunTime = Time.now

        res = kansa_api.get_members since_date if since_date
        res = kansa_api.get_members since_date if !since_date
        
        
        begin
        Person.transaction do
          res.each do |m|
            if m && m['member_number']

              # puts "*************** START"
              # puts m.to_s #if !m['public_last_name'] #m['membership'] != "Supporter"
              current = m
              
              # 1. check that the reg detail exists - if so it is an update
              # check to see if person with that member number exists
              reg_detail = RegistrationDetail.find_by(
                registration_number: m['member_number']
                )
              if reg_detail
                p = Planner::KansaImporter.find_kansa_person(m)
                if p == reg_detail.person
                  # puts "UPDATE " + m["legal_name"]
                  # puts "UPDATE " + m["member_number"]
                  # puts "UPDATE " + m["membership"]
                  reg_detail.registration_number = m['member_number']
                  reg_detail.registration_type = m['membership']
                  reg_detail.save!
                  # puts reg_detail.to_json
                  # puts reg_detail.person.to_json
                  # TODO - we may want to update name, email etc if applicable?
                # else
                #   puts "UPDATE MISTMATCH????"
                #   puts reg_detail.person.to_json
                end
              else
                # puts "CREATE " + m["legal_name"]
                person = Planner::KansaImporter.import_person m
                Planner::KansaImporter.create_member_details(person, m)
              end

              # puts "*************** END"
            end
          end
        end
        
        rescue => ex
          Rails.logger.error ex.message
          # Rails.logger.error ex.backtrace
          Rails.logger.error current
        end
        
        # Store the date in job info
        jobInfo.last_run = currentRunTime
        jobInfo.job_name = :kansa_import
        jobInfo.save!
      end
    end
  end

end
