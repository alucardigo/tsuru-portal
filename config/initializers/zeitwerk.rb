# frozen_string_literal: true

# Inflexões do autoloader para a integração FI Group (LeidoBem).
# Os arquivos são figroup_*.rb / figroup/ mas as constantes usam o G maiúsculo
# (FiGroup, FiGroupCredential, FiGroupProject) — sem estas regras o Zeitwerk
# esperaria Figroup/FigroupCredential e levantaria "uninitialized constant".
Rails.autoloaders.main.inflector.inflect(
  "figroup"            => "FiGroup",
  "figroup_credential" => "FiGroupCredential",
  "figroup_project"    => "FiGroupProject"
)
