require "rails_helper"

# Comportamento do concern FiGroupSyncable incluído em Demand: ao mudar um campo
# textual sincronizado (FieldMap::FIELD_PAIRS), marca push_pending no espelho FI.
RSpec.describe FiGroupSyncable, type: :model do
  # Demand persistida com um FiGroupProject espelho já vinculado e sem pendência.
  def demanda_com_espelho!
    demand = create(:demand)
    fp = FiGroupProject.create!(
      fi_project_id: "uuid-#{SecureRandom.hex(4)}",
      demand: demand,
      push_pending: false
    )
    [ demand, fp ]
  end

  it "está incluído em Demand" do
    expect(Demand.ancestors).to include(described_class)
  end

  it "marca push_pending ao mudar um campo mapeado (motivacao)" do
    demand, fp = demanda_com_espelho!

    demand.update!(motivacao: "Reduzir latência P99 sob concorrência alta")

    expect(fp.reload.push_pending).to be(true)
  end

  it "não marca push_pending ao mudar um campo não mapeado (description)" do
    demand, fp = demanda_com_espelho!

    demand.update!(description: "descrição nova, campo fora do FIELD_PAIRS")

    expect(fp.reload.push_pending).to be(false)
  end

  it "não quebra o save quando a Demand não tem espelho FI vinculado" do
    demand = create(:demand)

    expect { demand.update!(motivacao: "sem espelho vinculado") }.not_to raise_error
  end
end
