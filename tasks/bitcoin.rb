require 'fileutils'

module BitcoinRunner
  module Config
    HOST = {
      :temp_dir => '~/tmp/bitcoin',
      :data_dir  => '~/tmp/bitcoin/data',
      :config_dir => '~/tmp/bitcoin/bitcoin.conf',
      :dtach_socket => '~/tmp/bitcoin.dtach',
      :debug_file => '~/Library/Application\ Support/Bitcoin/debug.log' # I hate such dir names
    }
  end

  def self.debug_file
    Config::HOST[:debug_file]
  end
 
  def self.config_dir
    Config::HOST[:config_dir]
  end

  def self.dtach_socket
    Config::HOST[:dtach_socket]
  end

  def self.attach
    exec "dtach -a #{dtach_socket}"
  end

  def self.running?
    File.exists? dtach_socket 
  end

  def self.start
    bitcoin_cmd = 'bitcoin -gen=0 -connect=127.0.0.1'
    tail_cmd = "tail -f #{debug_file}"
    puts 'Detach with Ctrl+\ '
    puts 'Re-attach with rake bitcoin:attach'
    sleep 2
    exec "dtach -A #{dtach_socket} #{bitcoin_cmd}"
  end

  def self.stop
    sh 'killall bitcoin'
    rm dtach_socket
  end
end

namespace :bitcoin do
  desc 'Start Bitcoin'
  task :start do
    print 'Starting Bitcoin ...'
    BitcoinRunner.start
    puts 'done'
  end

  desc 'Stop Bitcoin'
  task :stop do
    print 'Stopping Bitcoin ...'
    BitcoinRunner.stop
    puts 'done'
  end

  desc 'Restart Bitcoin'
  task :restart => [:stop, :start]

  desc 'Attach to Bitcoin dtach socket'
  task :attach do
    BitcoinRunner.attach
  end
end

    

