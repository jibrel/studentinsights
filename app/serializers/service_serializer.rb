class ServiceSerializer < Struct.new :service

  def serialize_service
    service.as_json.symbolize_keys.slice(*[
      :id,
      :student_id,
      :provided_by_educator_name,
      :service_type_id,
      :date_started,
      :estimated_end_date,
      :recorded_by_educator_id,
      :recorded_at
    ]).merge({
      discontinued_by_educator_id: service.try(:discontinued_by_educator_id),
      discontinued_recorded_at: service.try(:discontinued_at)
    })
  end

  def self.service_types_index
    index = {}
    ServiceType.all.each do |service_type|
      index[service_type.id] = service_type.as_json(except: [:created_at, :updated_at]).symbolize_keys
    end
    index
  end

end
