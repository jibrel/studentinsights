class EducatorsImporter
  include Connector
  include Importer

  def import_row(row)
    educator = Educator.where(local_id: row[:local_id]).first_or_create!
    educator.update_attributes(Hash[row])
  end

end
