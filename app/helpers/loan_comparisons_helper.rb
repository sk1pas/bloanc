module LoanComparisonsHelper
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

	private

	def note_lines_block(lines, extra_class: nil)
		classes = ["table-note-lines", extra_class].compact.join(" ")
		content_tag(:div, class: classes) do
			safe_join(lines.map { |line| content_tag(:div, line, class: "table-note-line") })
		end
	end
end
