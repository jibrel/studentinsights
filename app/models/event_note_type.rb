# typed: true
class EventNoteType < ApplicationRecord
  def self.seed_for_all_districts
    EventNoteType.destroy_all
    EventNoteType.create!([
      { id: 300, name: 'SST Meeting' },
      { id: 301, name: 'MTSS Meeting' },
      { id: 302, name: 'Parent conversation' },
      { id: 304, name: 'Something else' },
      { id: 305, name: '9th Grade Experience' },
      { id: 306, name: '10th Grade Experience' },
      { id: 307, name: 'NEST' },
      { id: 308, name: 'Counselor Meeting' },
      { id: 400, name: 'BBST Meeting' },
      { id: 500, name: 'STAT Meeting' }, # deprecated
      { id: 501, name: 'CAT Meeting' }, # deprecated
      { id: 502, name: '504 Meeting' }, # deprecated
      { id: 503, name: 'SPED Meeting' } # deprecated
    ])
  end

  def self.SST
    EventNoteType.find(300)
  end

  def self.NGE
    EventNoteType.find(305)
  end

  def self.TENGE
    EventNoteType.find(306)
  end

  def self.NEST
    EventNoteType.find(307)
  end
end
