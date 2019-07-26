# typed: true
class AddLogToImporterRecords < ActiveRecord::Migration[5.1]
  def change
    add_column :import_records, :log, :text, default: ''
  end
end
