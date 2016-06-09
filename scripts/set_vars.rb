#
# Processes YAML files to create 'vars' files.
#

cwd = ARGV[1]

cwd ||= File.dirname(File.expand_path(__FILE__))

require 'yaml'

Dir.mkdir("#{cwd}/.work") unless File.exists?("#{cwd}/.work")

# load config settings
# puts "Loading #{cwd}/config.yaml for Vagrant configuration..."
profile    = YAML.load_file("#{cwd}/config.yaml")

# load local customizations
# (We really want to read these last, but we need to read the config file from here.)
local_path = "#{cwd}/local.yaml"
local      = {}
if File.exists? (local_path)
    # puts "Loading local overrides from #{local_path}..."
    local = YAML.load_file(local_path)
    local.each { |k, v|
        profile[k] = v
    }
end

# setup some fallback defaults - some of these are for backwards compatibility
profile['project']       ||= profile['name']
profile['host']          ||= profile['name']
profile['admin']         ||= "admin@#{profile['server']}"
profile['vm_user']       ||= profile['project']
profile['data_root']     ||= "/data/#{profile['project']}"
profile['home']          ||= "#{profile['data_root']}/home"
profile['server']        ||= profile['vm_ip']
profile['revision']      ||= profile['xnat_rev'] ||= ''
profile['xnat_rev']      ||= profile['revision']
profile['pipeline_rev']  ||= profile['revision']

# this ugliness reconciles and conforms [xnat] and [xnat_dir]
profile['xnat'] = profile['xnat_dir'] ||= profile['xnat'] ||= 'xnat'

# reconciles and conforms [pipeline_inst] and [pipeline_dir]
profile['pipeline_inst'] = profile['pipeline_dir'] ||= profile['pipeline_inst'] ||= 'pipeline'

profile['config']        ||= cfg_dir ||= ''
profile['provision']     ||= ''
profile['build']         ||= ''

if profile['host'] == ''
    profile['host'] = profile['name']
end

if profile['server'] == ''
    profile['server'] = profile['vm_ip']
end

if profile['xnat_url'] || profile['xnat_repo']
    profile['xnat_src'] = profile['xnat_url'] ||= profile['xnat_repo']
end

if profile['pipeline_url'] || profile['pipeline_repo']
    profile['pipeline_src'] = profile['pipeline_url'] ||= profile['pipeline_repo']
end

File.open("#{cwd}/.work/vars.sh", 'wb') { |vars|
    vars.truncate(0)
    vars.puts("#!/bin/bash\n")
    profile.each { |k, v|
        vars.puts "#{k.upcase}='#{v}'"
    }
}

File.open("#{cwd}/.work/vars.sed", 'wb') { |vars|
    vars.truncate(0)
    profile.each { |k, v|
        # Only put v in the sed file if it's a string. No subs for hashes.
        if v.is_a?(String)
            vars.puts "s/@#{k.upcase}@/#{v.gsub('/', "\\/")}/g"
        end
    }
}

File.open("#{cwd}/.work/vars.yaml", 'wb') { |vars|
    vars.truncate(0)
    vars.puts("# config vars\n")
    profile.each { |k, v|
        # Only put v in the sed file if it's a string. No subs for hashes.
        if v.is_a?(String)
            vars.puts "#{k}: '#{v}'"
        end
    }
}
