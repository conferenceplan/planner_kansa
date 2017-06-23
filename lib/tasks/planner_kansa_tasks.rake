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

    Apartment::Tenant.switch!(org)
    tenant =  PlannerMulti::Conference.find_by_subsite conference
    
    if tenant
      ActsAsTenant.with_tenant(tenant) do
        Kansa::Client.instance.configure do |config|
          config.username = user
          config.key = key
        end  
        
        m = Kansa::Member.new

        # since to get members (from last run)
        since_date = nil
        jobInfo = JobInfo.where(:job_name => :kansa_import).first # should only be one entry
        since_date = jobInfo.last_run if jobInfo
        jobInfo = JobInfo.new if !jobInfo

        currentRunTime = Time.now

        res = m.get_members since_date if since_date
        res = m.get_members since_date if !since_date
        
        Person.transaction do
          res.each do |m|
            if m && m['member_number']
              # puts m.to_s #if !m['public_last_name'] #m['membership'] != "Supporter"
              person = Planner::KansaImporter.import_person m
              Planner::KansaImporter.create_member_details(person, m)
              Planner::KansaImporter.create_postal_address(person, m)
            end
          end
        end
        
        # Store the date in job info
        jobInfo.last_run = currentRunTime
        jobInfo.job_name = :kansa_import
        jobInfo.save!
      end
    end
  end

end
