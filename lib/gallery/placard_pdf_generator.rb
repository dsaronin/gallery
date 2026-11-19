# frozen_string_literal: true

# ----------------------------------------------------------
# Gallery: A Photographer's gallery/portfolio tool
# Copyright (c) 2026 David S Anderson, All Rights Reserved
#
# Service: Gallery::PlacardPdfGenerator
# Encapsulates all Prawn PDF generation, multi-up sheet imposition,
# monochrome toner shading calibration, crop marks, typography,
# and ArtistMark colophon rendering for collection placards.
# ----------------------------------------------------------

require "prawn"
require "active_support/number_helper"

module Gallery
  class PlacardPdfGenerator
    include ActiveSupport::NumberHelper

    # --------------------------------------------------------
    # Geometric & Unit Conversion Constants
    # --------------------------------------------------------
    PT_PER_MM              = 2.834645669
    BASE_FONT_PT           = 12.0
    LINE_HEIGHT_RATIO      = 1.18

    # Internal Cell Padding & Vertical Spacers
    CELL_PADDING_EM        = 2.6
    SPACER_1X_EM           = 0.65
    SPACER_2X_EM           = 1.15

    # Typographic Scale Multipliers (relative to scaled base font size)
    PRIMARY_TITLE_EM       = 2.40
    PRIMARY_ARTIST_EM      = 2.40
    TITLE_STROKE_PT        = 0.35
    SECONDARY_EM           = 1.25
    YEAR_EM                = 1.05
    PRICE_EM               = 1.10
    SUBTITLE_EM            = 1.0
    BODY_EM                = 1.0
    SUBJECT_EM             = 0.90
    NOTES_PARAGRAPH_GAP_EM = 0.45
    SECONDARY_TOP_GAP_EM   = 0.25
    SUBJECT_TOP_GAP_EM     = 0.20
    SUBTITLE_BOTTOM_GAP_EM = 0.25

    # Crop Mark Geometry (Points)
    CROP_MARK_STROKE_PT    = 0.4
    CROP_TICK_HALF_LEN_PT  = 8.0
    CROP_EDGE_INSET_PT     = 14.0

    # Artist Mark Colophon Geometry (mirrors _artist_mark.sass two-cell modular lockup)
    COLOPHON_BOX_WIDTH_EM    = 14.0
    COLOPHON_REF_WIDTH_EM    = 10.5
    COLOPHON_BLEED_EM        = 0.0
    COLOPHON_CQI_RATIO       = 0.145
    COLOPHON_CELL_GAP_EM     = 0.12
    COLOPHON_LATIN_EM        = 0.90
    COLOPHON_LATIN_STROKE_PT = 0.45
    COLOPHON_KANJI_EM        = 0.82
    COLOPHON_KANJI_DROP_EM   = 0.34
    COLOPHON_BRAND_EM        = 0.135
    COLOPHON_BRAND_GAP_EM    = 0.04
    COLOPHON_HEIGHT_EM       = 2.40

    # --------------------------------------------------------
    # Monochrome Printer Shading Constants (Hex RGB Strings)
    # --------------------------------------------------------
    COLOR_DEEP_BLACK       = "000000" # Primary titles, body text, prices
    COLOR_CHARCOAL         = "1A1A1A" # Secondary artist attribution ($colorGray950)
    COLOR_COLOPHON_PRIMARY = "757575" # Muted colophon Latin mark ($MARK_PRIMARY_MUTED)
    COLOR_COLOPHON_SECOND  = "BDBDBD" # Muted colophon Kanji & Brand ($MARK_SECONDARY_MUTED)
    COLOR_CROP_MARK        = "888888" # Hairline interior cut guides
    COLOR_EMPTY_NOTICE     = "616161" # Empty collection notice ($colorGray700)

    # --------------------------------------------------------
    # Vendored Font Paths (app/assets/fonts)
    # --------------------------------------------------------
    FONTS_DIR              = File.expand_path("../../app/assets/fonts", __dir__).freeze
    BODY_FONT_FAMILY       = "LiberationSans"
    LATIN_MARK_FAMILY      = "Marcellus"
    CJK_MARK_FAMILY        = "NotoSerifCJK"

    BODY_FONT_FILES = {
      normal:      File.join(FONTS_DIR, "LiberationSans-Regular.ttf").freeze,
      bold:        File.join(FONTS_DIR, "LiberationSans-Bold.ttf").freeze,
      italic:      File.join(FONTS_DIR, "LiberationSans-Italic.ttf").freeze,
      bold_italic: File.join(FONTS_DIR, "LiberationSans-BoldItalic.ttf").freeze
    }.freeze

    LATIN_MARK_FONT_FILE   = File.join(FONTS_DIR, "Marcellus-Regular.ttf").freeze
    CJK_MARK_FONT_FILE     = File.join(FONTS_DIR, "NotoSerifCJK-Bold.ttc").freeze
    CJK_FALLBACK_FONT_FILE = "/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf"

    # --------------------------------------------------------
    # Public API
    # --------------------------------------------------------
    def initialize(collection, options = {})
      @collection   = collection
      @paper_size   = normalize_paper_size(options[:paper_size])
      @display_mode = normalize_display_mode(options[:display_mode] || options[:mode])
      @paper_spec   = ::Gallery::Environ::PLACARD_PAPER_SIZES.fetch(@paper_size)
    end

    def self.render(collection, options = {})
      new(collection, options).render
    end

    def render
      items = ordered_items
      sheet_layout = @paper_spec.fetch(:sheet_layout, :landscape)

      pdf = Prawn::Document.new(
        page_size:   ::Gallery::Environ::PLACARD_SHEET_SIZE,
        page_layout: sheet_layout,
        margin:      0
      )

      register_fonts(pdf)

      if items.empty?
        render_empty_sheet(pdf)
        return pdf.render
      end

      cols      = @paper_spec.fetch(:grid_cols)
      rows      = @paper_spec.fetch(:grid_rows)
      per_sheet = cols * rows

      cell_w = @paper_spec.fetch(:width_mm) * PT_PER_MM
      cell_h = @paper_spec.fetch(:height_mm) * PT_PER_MM

      # Center the ganged block cleanly on the physical sheet
      grid_w   = cols * cell_w
      grid_h   = rows * cell_h
      origin_x = (pdf.bounds.width - grid_w) / 2.0
      origin_y = pdf.bounds.height - ((pdf.bounds.height - grid_h) / 2.0)

      items.each_slice(per_sheet).with_index do |sheet_items, sheet_index|
        pdf.start_new_page if sheet_index.positive?

        sheet_items.each_with_index do |item, slot_index|
          col = slot_index % cols
          row = slot_index / cols

          cell_left = origin_x + (col * cell_w)
          cell_top  = origin_y - (row * cell_h)

          pdf.bounding_box([cell_left, cell_top], width: cell_w, height: cell_h) do
            render_placard_cell(pdf, item.placard_data)
          end
        end

        draw_crop_marks(pdf, origin_x: origin_x, origin_y: origin_y, cols: cols, rows: rows, cell_w: cell_w, cell_h: cell_h)
      end

      pdf.render
    end

    private

    def ordered_items
      return [] unless @collection.respond_to?(:items_association)

      @collection.items_association.includes(:photo, :placard).order(:position).to_a
    end

    def normalize_paper_size(raw)
      sym = raw.to_s.downcase.to_sym
      ::Gallery::Environ::PLACARD_PAPER_SIZES.key?(sym) ? sym : ::Gallery::Environ::DEFAULT_PLACARD_PAPER_SIZE
    end

    def normalize_display_mode(raw)
      sym = raw.to_s.downcase.to_sym
      ::Gallery::Environ::PLACARD_DISPLAY_MODES.key?(sym) ? sym : ::Gallery::Environ::DEFAULT_PLACARD_DISPLAY_MODE
    end

    def register_fonts(pdf)
      pdf.font_families.update(
        BODY_FONT_FAMILY  => BODY_FONT_FILES,
        LATIN_MARK_FAMILY => { normal: LATIN_MARK_FONT_FILE, bold: LATIN_MARK_FONT_FILE }
      )

      cjk_spec = resolve_cjk_font_spec
      if cjk_spec
        pdf.font_families.update(
          CJK_MARK_FAMILY => { normal: cjk_spec, bold: cjk_spec }
        )
        @cjk_font_available = true
      else
        @cjk_font_available = false
      end

      pdf.font(BODY_FONT_FAMILY)
    end

    def resolve_cjk_font_spec
      return { file: CJK_MARK_FONT_FILE, font: 0 } if File.exist?(CJK_MARK_FONT_FILE)
      return CJK_FALLBACK_FONT_FILE if File.exist?(CJK_FALLBACK_FONT_FILE)

      nil
    end

    def render_empty_sheet(pdf)
      pdf.fill_color(COLOR_EMPTY_NOTICE)
      pdf.font(BODY_FONT_FAMILY, style: :italic, size: BASE_FONT_PT) do
        pdf.text_box(
          "No curated items available for placard export.",
          at:     [0, pdf.bounds.height / 2.0],
          width:  pdf.bounds.width,
          align:  :center
        )
      end
    end

    def render_placard_cell(pdf, pd)
      scale   = @paper_spec.fetch(:scale)
      base_pt = BASE_FONT_PT * scale
      pad_pt  = CELL_PADDING_EM * base_pt

      inner_w = pdf.bounds.width - (2.0 * pad_pt)
      inner_h = pdf.bounds.height - (2.0 * pad_pt)

      # Reserve bottom band so long curatorial notes never collide with the colophon
      colophon_reserve_h = (COLOPHON_HEIGHT_EM * base_pt)

      pdf.bounding_box([pad_pt, pdf.bounds.height - pad_pt], width: inner_w, height: inner_h - colophon_reserve_h) do
        pdf.font(BODY_FONT_FAMILY)
        pdf.fill_color(COLOR_DEEP_BLACK)

        if @display_mode == :group
          render_group_header(pdf, pd, base_pt)
        else
          render_solo_header(pdf, pd, base_pt)
        end

        pdf.move_down(SPACER_1X_EM * base_pt)

        if pd.medium.present?
          render_body_line(pdf, pd.medium, base_pt)
        end

        if pd.dimensions_display.present?
          render_body_line(pdf, pd.dimensions_display, base_pt)
        end

        pdf.move_down(SPACER_1X_EM * base_pt)

        if pd.price.present?
          price_str = format_price(pd.price)
          price_pt  = PRICE_EM * base_pt
          if price_str.present? && pdf.cursor >= price_pt
            pdf.fill_color(COLOR_DEEP_BLACK)
            pdf.font(BODY_FONT_FAMILY, style: :bold, size: price_pt) do
              pdf.text(price_str, leading: leading_for(price_pt))
            end
          end
        end

        pdf.move_down([SPACER_2X_EM * base_pt, pdf.cursor].min)

        if pd.subtitle.present?
          sub_pt = SUBTITLE_EM * base_pt
          if pdf.cursor >= sub_pt
            pdf.fill_color(COLOR_DEEP_BLACK)
            pdf.font(BODY_FONT_FAMILY, style: :italic, size: sub_pt) do
              pdf.text(pd.subtitle, leading: leading_for(sub_pt))
            end
            pdf.move_down([SUBTITLE_BOTTOM_GAP_EM * base_pt, pdf.cursor].min)
          end
        end

        if pd.curatorial_notes.present? && pdf.cursor.positive?
          render_notes(pdf, pd.curatorial_notes, base_pt)
        end
      end

      render_colophon(pdf, base_pt, pad_pt)
    end

    def render_solo_header(pdf, pd, base_pt)
      title_text = pd.title.presence || "Untitled"
      title_pt   = PRIMARY_TITLE_EM * base_pt
      year_pt    = YEAR_EM * base_pt

      fragments = [
        { text: title_text, styles: [:bold, :italic], size: title_pt, color: COLOR_DEEP_BLACK }
      ]
      if pd.date_created_display.present?
        fragments << { text: "   #{pd.date_created_display}", styles: [], size: year_pt, color: COLOR_DEEP_BLACK }
      end

      # Render a zero-offset bold-italic overstrike pass for the title alone, then lay out title + year normally
      start_y = pdf.cursor
      pdf.save_graphics_state do
        pdf.fill_color(COLOR_DEEP_BLACK)
        pdf.stroke_color(COLOR_DEEP_BLACK)
        pdf.line_width(TITLE_STROKE_PT * @paper_spec.fetch(:scale))
        pdf.text_rendering_mode(:fill_stroke) do
          pdf.font(BODY_FONT_FAMILY, style: :bold_italic, size: title_pt) do
            pdf.text(title_text, leading: leading_for(title_pt, 1.15))
          end
        end
      end

      pdf.move_cursor_to(start_y)
      pdf.formatted_text(fragments, leading: leading_for(title_pt, 1.15))

      if pd.artist_name.present?
        pdf.move_down(SECONDARY_TOP_GAP_EM * base_pt)
        artist_pt = SECONDARY_EM * base_pt
        pdf.fill_color(COLOR_CHARCOAL)
        pdf.font(BODY_FONT_FAMILY, style: :normal, size: artist_pt) do
          pdf.text(pd.artist_name, leading: leading_for(artist_pt))
        end
      end

      render_subject_line(pdf, pd, base_pt)
    end

    def render_group_header(pdf, pd, base_pt)
      if pd.artist_name.present?
        artist_pt = PRIMARY_ARTIST_EM * base_pt
        pdf.save_graphics_state do
          pdf.fill_color(COLOR_DEEP_BLACK)
          pdf.stroke_color(COLOR_DEEP_BLACK)
          pdf.line_width(TITLE_STROKE_PT * @paper_spec.fetch(:scale))
          pdf.text_rendering_mode(:fill_stroke) do
            pdf.font(BODY_FONT_FAMILY, style: :bold, size: artist_pt) do
              pdf.text(pd.artist_name, leading: leading_for(artist_pt, 1.15))
            end
          end
        end
        pdf.move_down(SECONDARY_TOP_GAP_EM * base_pt)
      end

      title_text = pd.title.presence || "Untitled"
      title_pt   = SECONDARY_EM * base_pt
      year_pt    = YEAR_EM * base_pt

      fragments = [
        { text: title_text, styles: [:italic], size: title_pt, color: COLOR_DEEP_BLACK }
      ]
      if pd.date_created_display.present?
        fragments << { text: "   #{pd.date_created_display}", styles: [], size: year_pt, color: COLOR_DEEP_BLACK }
      end

      pdf.formatted_text(fragments, leading: leading_for(title_pt, 1.25))

      render_subject_line(pdf, pd, base_pt)
    end

    def render_subject_line(pdf, pd, base_pt)
      return unless pd.subject.present?

      pdf.move_down(SUBJECT_TOP_GAP_EM * base_pt)
      subj_pt = SUBJECT_EM * base_pt
      pdf.fill_color(COLOR_DEEP_BLACK)
      pdf.font(BODY_FONT_FAMILY, style: :italic, size: subj_pt) do
        pdf.text("Subject: #{pd.subject}", leading: leading_for(subj_pt, 1.25))
      end
    end

    def render_body_line(pdf, text_value, base_pt)
      body_pt = BODY_EM * base_pt
      return if pdf.cursor < body_pt

      pdf.fill_color(COLOR_DEEP_BLACK)
      pdf.font(BODY_FONT_FAMILY, style: :normal, size: body_pt) do
        pdf.text(text_value, leading: leading_for(body_pt))
      end
    end

    def render_notes(pdf, raw_notes, base_pt)
      notes_pt   = BODY_EM * base_pt
      avail_h    = pdf.cursor
      return if avail_h < notes_pt

      paragraphs = raw_notes.to_s.split(/\r?\n\s*\r?\n/).map { |p| p.strip.gsub(/\r?\n/, " ") }.reject(&:empty?)
      joined     = paragraphs.join("\n\n")

      pdf.fill_color(COLOR_DEEP_BLACK)
      pdf.font(BODY_FONT_FAMILY, style: :normal, size: notes_pt) do
        pdf.text_box(
          joined,
          at:       [0, avail_h],
          width:    pdf.bounds.width,
          height:   avail_h,
          leading:  leading_for(notes_pt, 1.4),
          overflow: :truncate
        )
      end
    end

    def render_colophon(pdf, base_pt, pad_pt)
      # Mirrors .wall-placard-colophon in _placard.sass & .artist-mark in _artist_mark.sass
      box_w    = COLOPHON_BOX_WIDTH_EM * base_pt
      ref_w    = COLOPHON_REF_WIDTH_EM * base_pt
      bleed_pt = COLOPHON_BLEED_EM * base_pt
      mark_em  = ref_w * COLOPHON_CQI_RATIO

      latin_pt = COLOPHON_LATIN_EM * mark_em
      kanji_pt = COLOPHON_KANJI_EM * mark_em
      brand_pt = COLOPHON_BRAND_EM * mark_em
      gap_pt   = COLOPHON_CELL_GAP_EM * mark_em

      box_h    = COLOPHON_HEIGHT_EM * base_pt
      box_left = pdf.bounds.width - pad_pt - box_w + bleed_pt
      box_top  = pad_pt - bleed_pt + box_h

      artist_name  = ::Gallery::Environ::ARTIST_NAME
      artist_kanji = ::Gallery::Environ::ARTIST_NAME_KANJI
      artist_brand = ::Gallery::Environ::ARTIST_BRAND

      pdf.bounding_box([box_left, box_top], width: box_w, height: box_h) do
        latin_w = pdf.width_of(artist_name, font: LATIN_MARK_FAMILY, style: :bold, size: latin_pt)
        kanji_chars = artist_kanji.to_s.chars
        kanji_w = if @cjk_font_available && kanji_chars.any?
                    kanji_chars.length * kanji_pt
                  else
                    pdf.width_of(artist_brand, font: LATIN_MARK_FAMILY, style: :bold, size: brand_pt) * 1.6
                  end

        total_w = latin_w + gap_pt + kanji_w
        start_x = [box_w - total_w, 0.0].max

        # Left Cell: Latin Artist Name (Marcellus thickened via matching-color :fill_stroke mode)
        pdf.save_graphics_state do
          pdf.fill_color(COLOR_COLOPHON_PRIMARY)
          pdf.stroke_color(COLOR_COLOPHON_PRIMARY)
          pdf.line_width(COLOPHON_LATIN_STROKE_PT * @paper_spec.fetch(:scale))
          pdf.font(LATIN_MARK_FAMILY, style: :bold, size: latin_pt) do
            pdf.text_box(
              artist_name,
              at:          [start_x, box_h],
              width:       latin_w + 6.0,
              height:      box_h,
              valign:      :center,
              mode:        :fill_stroke,
              single_line: true
            )
          end
        end

        # Right Cell Stack: Kanji (Mincho serif, explicit 1-em cells) + justified Brand
        stack_x       = start_x + latin_w + gap_pt
        kanji_line_h  = kanji_pt * 1.15
        brand_line_h  = brand_pt * 1.25
        brand_gap     = COLOPHON_BRAND_GAP_EM * brand_pt
        stack_total_h = (@cjk_font_available ? kanji_line_h + brand_gap : 0.0) + brand_line_h
        stack_top_y   = (box_h + stack_total_h) / 2.0
        kanji_top_y   = stack_top_y - (COLOPHON_KANJI_DROP_EM * kanji_pt)

        pdf.fill_color(COLOR_COLOPHON_SECOND)

        if @cjk_font_available && kanji_chars.any?
          pdf.font(CJK_MARK_FAMILY, style: :bold, size: kanji_pt) do
            kanji_chars.each_with_index do |ch, idx|
              pdf.text_box(
                ch,
                at:          [stack_x + (idx * kanji_pt), kanji_top_y],
                width:       kanji_pt * 1.3,
                height:      kanji_line_h * 1.3,
                align:       :left,
                mode:        :fill,
                single_line: true
              )
            end
          end
        end

        if kanji_w.positive?
          brand_top_y = @cjk_font_available ? (stack_top_y - kanji_line_h - brand_gap) : stack_top_y
          render_justified_brand(
            pdf,
            artist_brand,
            x:     stack_x,
            top_y: brand_top_y,
            width: kanji_w,
            size:  brand_pt
          )
        end
      end
    end

    def render_justified_brand(pdf, text, x:, top_y:, width:, size:)
      chars = text.to_s.chars
      return if chars.empty?

      pdf.font(LATIN_MARK_FAMILY, style: :bold, size: size) do
        if chars.length == 1
          pdf.text_box(text, at: [x, top_y], width: width, height: size * 1.4, align: :center)
          return
        end

        char_widths   = chars.map { |ch| pdf.width_of(ch, font: LATIN_MARK_FAMILY, style: :bold, size: size) }
        total_glyph_w = char_widths.sum
        step_gap      = (width - total_glyph_w) / (chars.length - 1).to_f

        cursor_x = x
        chars.each_with_index do |ch, idx|
          pdf.text_box(
            ch,
            at:     [cursor_x, top_y],
            width:  char_widths[idx] + 2.0,
            height: size * 1.4,
            align:  :left
          )
          cursor_x += char_widths[idx] + step_gap
        end
      end
    end

    def draw_crop_marks(pdf, origin_x:, origin_y:, cols:, rows:, cell_w:, cell_h:)
      grid_w = cols * cell_w
      grid_h = rows * cell_h
      bottom_y = origin_y - grid_h
      right_x  = origin_x + grid_w

      pdf.save_graphics_state do
        pdf.stroke_color(COLOR_CROP_MARK)
        pdf.line_width(CROP_MARK_STROKE_PT)

        # Interior vertical cut guides (top/bottom edge ticks + interior crosshairs)
        (1...cols).each do |col|
          x = origin_x + (col * cell_w)

          # Top edge tick
          pdf.stroke_line([x, origin_y - CROP_EDGE_INSET_PT], [x, origin_y - CROP_EDGE_INSET_PT - (CROP_TICK_HALF_LEN_PT * 2)])
          # Bottom edge tick
          pdf.stroke_line([x, bottom_y + CROP_EDGE_INSET_PT], [x, bottom_y + CROP_EDGE_INSET_PT + (CROP_TICK_HALF_LEN_PT * 2)])

          # Interior row intersection crosshairs
          (1...rows).each do |row|
            y = origin_y - (row * cell_h)
            pdf.stroke_line([x - CROP_TICK_HALF_LEN_PT, y], [x + CROP_TICK_HALF_LEN_PT, y])
            pdf.stroke_line([x, y - CROP_TICK_HALF_LEN_PT], [x, y + CROP_TICK_HALF_LEN_PT])
          end
        end

        # Interior horizontal cut guides (left/right edge ticks)
        (1...rows).each do |row|
          y = origin_y - (row * cell_h)

          # Left edge tick
          pdf.stroke_line([origin_x + CROP_EDGE_INSET_PT, y], [origin_x + CROP_EDGE_INSET_PT + (CROP_TICK_HALF_LEN_PT * 2), y])
          # Right edge tick
          pdf.stroke_line([right_x - CROP_EDGE_INSET_PT, y], [right_x - CROP_EDGE_INSET_PT - (CROP_TICK_HALF_LEN_PT * 2), y])
        end
      end
    end

    def leading_for(font_pt, ratio = LINE_HEIGHT_RATIO)
      # TrueType metrics already carry ~1.15x line height; add only incremental leading
      extra = [ratio - 1.15, 0.0].max
      (font_pt * extra).round(2)
    end

    def format_price(price)
      return nil if price.nil?
      return "Not for Sale" if price.zero?

      "$#{number_to_delimited(price)}"
    end

#  **************************************************
  end  # class PplacardPdfGenerator
end    # module
