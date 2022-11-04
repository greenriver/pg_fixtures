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

  def initialize(
    model:,
    directory: "pg_fixtures",
    excluded_tables: EXCLUDED_TABLES
  )
    @directory = directory
    @excluded_tables = excluded_tables
    @model = model
  end

  # Saves the contents of the database to a text file
  #
  # @param force [Boolean] if true, remove any previously saved fixtures,
  # if false, don't overwrite a previous fixture
  def store(force: false)
    return if exists? && !force

    remove if force
    pg_dump
  end

  # loads the contents of the sql file into the database
  # truncating each table before loading
  def restore
    truncate
    # NOTE: you must store the connection information in `.pg_pass` for this to work
    # puts "Running psql #{db_options} #{db_name} -f #{file_path}"
    `psql #{db_options} -f #{file_path}`
    fix_sequences
  end

  def exists?
    File.exist?(file_path)
  end

  private

  def pg_dump
    # NOTE: you must store the connection information in `.pg_pass` for this to work
    # puts "Running: pg_dump #{db_options} #{pg_table_string} --data-only #{db_name} > #{file_path}"
    puts `cat ~/.pgpass`
    puts "pg_dump #{db_options} #{pg_table_string} --data-only > #{file_path}"
    `pg_dump #{db_options} #{pg_table_string} --data-only > #{file_path}`
  end

  def db_options
    # [].tap do |options|
    #   options << "-h #{host}" if host.present?
    #   options << "-U #{username}" if username.present?
    #   options << "-p #{port}" if port.present?
    # end.join(' ')
    "postgresql://#{username}:#{password}@#{host}:#{port}/#{db_name}"
  end

  def pg_table_string
    return '' unless excluded_tables.present?

    "--exclude-table='#{excluded_tables.map { |t| "\"#{t}\"" }.join('|')}'"
  end

  def file_path
    File.join(directory, "#{db_name}.sql")
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

  def truncate
    tables.each do |table|
      connection.execute(
        "TRUNCATE TABLE #{connection.quote_table_name(table)} RESTART IDENTITY CASCADE"
      )
    end
  end

  def fix_sequences
    query = <<~SQL
      SELECT 'SELECT SETVAL(' ||
        quote_literal(quote_ident(PGT.schemaname) || '.' || quote_ident(S.relname)) ||
        ', COALESCE(MAX(' ||quote_ident(C.attname)|| '), 1) ) FROM ' ||
        quote_ident(PGT.schemaname)|| '.'||quote_ident(T.relname)|| ';'
      FROM pg_class AS S,
          pg_depend AS D,
          pg_class AS T,
          pg_attribute AS C,
          pg_tables AS PGT
      WHERE S.relkind = 'S'
          AND S.oid = D.objid
          AND D.refobjid = T.oid
          AND D.refobjid = C.attrelid
          AND D.refobjsubid = C.attnum
          AND T.relname = PGT.tablename
      ORDER BY S.relname;
    SQL
    result = connection.select_all(query)
    result.rows.flatten.each do |q|
      connection.execute(q)
    end
  end

  def configuration
    model.connection_db_config.configuration_hash
  end

  def db_name
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
    configuration[:port].presence || 5432
  end
end
