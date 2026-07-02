# frozen_string_literal: true

# Bloco J — Combina transições de estado, comentários, uploads de documento e
# diffs de campo (PaperTrail) numa única linha do tempo cronológica, para dar
# uma visão completa e legível do histórico de uma demanda (útil para defesa Lei do Bem).
module Demands
  module TimelineBuilder
    Event = Struct.new(:type, :created_at, :actor, :payload, keyword_init: true)

    module_function

    def call(demand)
      events = []
      events.concat(transition_events(demand))
      events.concat(comment_events(demand))
      events.concat(document_events(demand))
      events.concat(version_events(demand))
      events.sort_by { |e| e.created_at || Time.at(0) }.reverse
    end

    def transition_events(demand)
      demand.transitions.includes(:actor).map do |t|
        Event.new(type: :transition, created_at: t.created_at, actor: t.actor,
                  payload: { from_state: t.from_state, to_state: t.to_state, event: t.event, justification: t.justification })
      end
    end

    def comment_events(demand)
      demand.comments.includes(:user).map do |c|
        Event.new(type: :comment, created_at: c.created_at, actor: c.user, payload: { body: c.body })
      end
    end

    def document_events(demand)
      (demand.documentos.attachments.to_a + demand.attachments.attachments.to_a).map do |att|
        uploader_id = att.metadata["uploaded_by_id"]
        actor = uploader_id ? User.find_by(id: uploader_id) : nil
        Event.new(type: :document, created_at: att.created_at, actor: actor,
                  payload: { filename: att.filename.to_s, byte_size: att.byte_size, blob: att.blob })
      end
    end

    def version_events(demand)
      demand.versions.map do |v|
        author = v.whodunnit.present? ? User.find_by(id: v.whodunnit) : nil
        changes = v.changeset.is_a?(Hash) ? v.changeset.except("updated_at", "created_at", "aasm_state") : {}
        next nil if v.event == "update" && changes.empty?

        Event.new(type: :version, created_at: v.created_at, actor: author,
                  payload: { event: v.event, changes: changes })
      end.compact
    end
  end
end
