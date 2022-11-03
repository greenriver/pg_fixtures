# frozen_string_literal: true

require_relative "pg_fixtures/version"

##
# PgFixtures provides a mechanism to efficiently store and load data from postgres
class PgFixtures
  class Error < StandardError; end

  EXCLUDED_TABLES = %w[
    ar_internal_metadata
    delayed_jobs
    schema_info
    schema_migrations
  ].freeze

  attr_accessor :directory, :excluded_tables, :model

  def initialize(directory: 'pg_fixtures', excluded_tables: EXCLUDED_TABLES, model:)
    @directory = directory
    @excluded_tables = excluded_tables
    @model = model
  end

  # Saves the contents of the database to a text file
  #
  # @param force [Boolean] if true, remove any previously saved fixtures,
  # if false, don't overwrite a previous fixture
  def store(force: false)
    return if exits? && !force

    remove if force
    pg_dump
  end

  def restore
  end

  def pg_dump
    # sending connection string, including password on the command line
    # is not great, but this should only be used in a test environment
    options = "-h #{host} -p #{port} -U #{username} #{pg_table_string} --data-only"
    `PGPASSWORD=#{password} pg_dump #{options} #{database_name} > #{file_path}`
  end

  private

  def pg_table_string
    tables.map { |t| "--table #{t}" }.join(' ')
  end

  def file_path
    File.join(directory, "#{database_name}.sql")
  end

  def exists?
    File.exist?(file_path)
  end

  def remove
    FileUtils.rm_f(file_path)
  end

  def connection
    model.connection
  end

  def tables
    connection.tables - excluded_tables
  end

  def configuration
    connection_db_config.configuration_hash
  end

  def database_name
    configuration[:database]
  end

  def username
    configuration[:username]
  end

  def password
    configuration[:password]
  end

  def host
    configuration[:host]
  end

  def port
    configuration[:port]
  end
end
