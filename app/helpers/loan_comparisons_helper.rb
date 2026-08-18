module LoanComparisonsHelper
	def payment_parts_expanded?
		cookies[:payment_parts_open] != "0"
	end

	def incomplete_insurance_note(result)
		life = result[:life_insurance_unknown]
		property = result[:property_insurance_unknown]
		return unless life || property

		key = if life && property
			"both"
		elsif life
			"life"
		else
			"property"
		end

		t("home.results.incomplete_insurance_note.#{key}")
	end

	def first_month_breakdown(lines)
		parts = Array(lines).map { |line| line.to_s.strip }.reject(&:blank?)
		return if parts.empty?

		content_tag(:div, class: "first-month-breakdown") do
			safe_join(parts.map { |line| first_month_breakdown_row(line) })
		end
	end

	def expandable_note(note, max_length: 140)
		text = note.to_s.strip
		return if text.blank?

		return content_tag(:div, text, class: "table-note") if text.length <= max_length

		content_tag(:details, class: "table-note-expandable") do
			safe_join(
				[
					content_tag(:summary, t("home.results.show_notes"), class: "table-note-summary"),
					content_tag(:div, text, class: "table-note mt-1")
				]
			)
		end
	end

	def expandable_note_lines(lines, max_length: 180)
		parts = Array(lines).map { |line| line.to_s.strip }.reject(&:blank?)
		return if parts.empty?

		combined = parts.join(" ")
		return note_lines_block(parts) if combined.length <= max_length

		content_tag(:details, class: "table-note-expandable") do
			safe_join(
				[
					content_tag(:summary, t("home.results.show_notes"), class: "table-note-summary"),
					note_lines_block(parts, extra_class: "mt-1")
				]
			)
		end
	end

	def bank_offer_logo_tag(logo, alt:)
		return unless logo&.attached?

		image_tag logo.variant(resize_to_limit: [100, 50]),
							class: "bank-offer-logo",
							alt: alt,
							width: 100,
							height: 50
	end

	def labeled_range_tag(id, label, **attributes)
		safe_join(
			[
				label_tag(id, label, class: "visually-hidden"),
				tag.input(**attributes, type: "range", id: id)
			]
		)
	end

	private

	def first_month_breakdown_row(line)
		label, value = split_note_label_value(line)

		if value.present?
			content_tag(:div, class: "first-month-breakdown-row") do
				safe_join(
					[
						content_tag(:span, label, class: "first-month-breakdown-label"),
						content_tag(:strong, value, class: "first-month-breakdown-value")
					]
				)
			end
		else
			content_tag(:div, line, class: "first-month-breakdown-note")
		end
	end

	def split_note_label_value(line)
		label, value = line.split(":", 2).map { |part| part&.strip }
		return [line, nil] if value.blank?

		["#{label}:", value]
	end

	def note_lines_block(lines, extra_class: nil)
		classes = ["table-note-lines", extra_class].compact.join(" ")
		content_tag(:div, class: classes) do
			safe_join(lines.map { |line| content_tag(:div, line, class: "table-note-line") })
		end
	end
end
