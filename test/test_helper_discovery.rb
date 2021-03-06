def set_session_user(user)
  SETTINGS[:login] ? {:user => user.id, :expires_at => 5.minutes.from_now} : {}
end

def user_with_perms(perms)
  perms = perms.collect{|p| Permission.find_by_name(p) || Permission.create(:name => p) }
  perms.each do |p|
    p.resource_type = 'Host' if p.name =~ /discovered_hosts$/
    p.resource_type = 'DiscoveryRule' if p.name =~ /discovery_rules$/
    p.save!
  end
  role = FactoryGirl.create :role
  perms.each do |perm|
    FactoryGirl.create(:filter, :role => role, :permissions => [perm])
  end
  user = FactoryGirl.create :user, :with_mail, :admin => false
  user.roles << role
  user.save
  user
end

def as_default_manager
  as_user(default_manager) do
    yield
  end
end

def as_default_reader
  as_user(default_reader) do
    yield
  end
end

def default_manager
  @default_manager ||= user_with_perms(Foreman::Plugin.find('foreman_discovery').default_roles['Discovery Manager'])
end

def default_reader
  @default_reader ||= user_with_perms(Foreman::Plugin.find('foreman_discovery').default_roles['Discovery Reader'])
end

def set_session_user_default_reader
  set_session_user(default_reader)
end

def set_session_user_default_manager
  set_session_user(default_manager)
end

def extract_form_errors(response)
  response.body.scan(/error-message[^<]*</)
end

def set_default_settings
  FactoryGirl.create(:setting, :name => 'discovery_fact', :value => 'discovery_bootif', :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_hostname', :value => 'discovery_bootif', :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_auto', :value => true, :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_reboot', :value => true, :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_organization', :value => "Organization 1", :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_location', :value => "Location 1", :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_prefix', :value => 'mac', :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_clean_facts', :value => false, :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_lock', :value => 'false', :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_lock_template', :value => 'pxelinux_discovery', :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_pxelinux_lock_template', :value => 'pxelinux_discovery', :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_pxegrub_lock_template', :value => 'pxegrub_discovery', :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_pxegrub2_lock_template', :value => 'pxegrub2_discovery', :category => 'Setting::Discovered')
  FactoryGirl.create(:setting, :name => 'discovery_always_rebuild_dns', :value => true, :category => 'Setting::Discovered')
end

def setup_hostgroup(host)
  domain = FactoryGirl.create(:domain)
  subnet = FactoryGirl.create(:subnet_ipv4, :network => "192.168.100.0")
  environment = FactoryGirl.create(:environment, :organizations => [host.organization], :locations => [host.location])
  medium = FactoryGirl.create(:medium, :organizations => [host.organization], :locations => [host.location])
  os = FactoryGirl.create(:operatingsystem, :with_ptables, :with_archs, :media => [medium])
  hostgroup = FactoryGirl.create(
    :hostgroup, :with_rootpass, :with_puppet_orchestration,
    :operatingsystem => os,
    :architecture => os.architectures.first,
    :ptable => os.ptables.first,
    :medium => os.media.first,
    :environment => environment,
    :subnet => subnet,
    :domain => domain,
    :organizations => [host.organization], :locations => [host.location])
  domain.subnets << hostgroup.subnet
  hostgroup.medium.organizations |= [host.organization]
  hostgroup.medium.locations |= [host.location]
  hostgroup.ptable.organizations |= [host.organization]
  hostgroup.ptable.locations |= [host.location]
  hostgroup.domain.organizations |= [host.organization]
  hostgroup.domain.locations |= [host.location]
  hostgroup.subnet.organizations |= [host.organization]
  hostgroup.subnet.locations |= [host.location]
  hostgroup.environment.organizations |= [host.organization]
  hostgroup.environment.locations |= [host.location]
  hostgroup.puppet_proxy.organizations |= [host.organization]
  hostgroup.puppet_proxy.locations |= [host.location]
  hostgroup.puppet_ca_proxy.organizations |= [host.organization]
  hostgroup.puppet_ca_proxy.locations |= [host.location]
  hostgroup
end

def organization_one
  Organization.find_by_name('Organization 1')
end

def location_one
  Location.find_by_name('Location 1')
end
