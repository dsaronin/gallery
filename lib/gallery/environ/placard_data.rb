# frozen_string_literal: true

# Gallery:
# Copyright (c) 2026 David S Anderson, All Rights Reserved
#
# ==============================================================================
# Gallery::Environ::PlacardData — Internal API Specification
# ==============================================================================
#
# PURPOSE:
#   Immutable value object and functional cascade engine for GALLERY display
#   placards. Encapsulates resolved placard attribute values, dual-track
#   field partitioning (ITEM vs. COLLECTION), Ruby class introspection, and
#   per-field provenance tracking (:intrinsic, :default, :direct, :cascaded).
#
# DUAL-TRACK FIELD PARTITIONS:
#   Placard attributes are divided into two mutually exclusive tracks:
#
#   1. ITEM_FIELDS (Work-specific identity & narrative):
#      [:title, :subtitle, :curatorial_notes, :date_created_display, :location_display]
#      - Cascade Chain: Photo (intrinsic) -> PortfolioItem -> ExhibitionItem -> Placard
#
#   2. COLLECTION_FIELDS (Shared staging, physical specs, pricing & licensing):
#      [:artist_name, :medium, :dimensions_display, :edition_info, :price,
#       :sales_notes, :cc_license, :copyright_year, :copyright_holder]
#      - Cascade Chain: Portfolio -> Exhibition -> Placard
#
#   3. UNIVERSAL (Placard record override):
#      A persisted Placard record sits at the top of both chains and may
#      supply or override fields from either ITEM_FIELDS or COLLECTION_FIELDS.
#
# RUBY METAPROGRAMMING & PARTITION INTROSPECTION:
#   PlacardData inspects the class hierarchy (via `ancestors` and class names)
#   of any participating domain object passed to `#merge` or `#partition_for`:
#     - Item sources:       Photo, PortfolioItem, ExhibitionItem  => :item
#     - Collection sources: Portfolio, Exhibition                 => :collection
#     - Universal sources:  Placard                             => :universal
#   A PlacardData instance can be queried directly via `#active_partition`,
#   `#item_partition?`, and `#collection_partition?`.
#
# FUNCTIONAL MERGE & PROVENANCE SEMANTICS:
#   - `#merge(source, raw_attrs = {}, status: :direct)` returns a NEW PlacardData
#     instance without mutating the receiver.
#   - Only non-blank attributes belonging to `allowed_fields_for(source)` are
#     applied. Note: numeric `0` (e.g., price: 0, cc_license: 0) is treated as
#     present, whereas `nil` and whitespace-only strings are ignored.
#   - Existing populated fields from an upstream PlacardData that are NOT
#     overwritten in the current merge transition their status to `:cascaded`
#     while retaining their original `source_class` and `source_id`.
#   - Newly applied fields record the incoming `status` (:intrinsic, :default,
#     or :direct) along with the incoming `source_class` and `source_id`.
#
# ATTRIBUTE ACCESSORS & HELPERS:
#   - Direct readers exist for every field in ALL_FIELDS, plus `#name` as an
#     alias for `#title`.
#   - Provenance queries: `#direct?(field)`, `#cascaded?(field)`,
#     `#intrinsic?(field)`, `#default?(field)`, `#provenance_for(field)`,
#     `#source_label_for(field)`.
#   - Licensing helpers: `#cc_license_key` and `#cc_license_label` resolve
#     integer or symbol enum values via `Gallery::Environ::CcLicense`.
# ==============================================================================

module Gallery
  class Environ
    class PlacardData
      ITEM_FIELDS = %i[
        title
        subtitle
        curatorial_notes
        date_created_display
        location_display
      ].freeze

      COLLECTION_FIELDS = %i[
        artist_name
        medium
        dimensions_display
        edition_info
        price
        sales_notes
        cc_license
        copyright_year
        copyright_holder
      ].freeze

      ALL_FIELDS = (ITEM_FIELDS + COLLECTION_FIELDS).freeze

      ITEM_CLASS_NAMES       = %w[Photo PortfolioItem ExhibitionItem].freeze
      COLLECTION_CLASS_NAMES = %w[Portfolio Exhibition].freeze
      UNIVERSAL_CLASS_NAMES  = %w[Placard].freeze

      VALID_STATUSES = %i[intrinsic default direct cascaded].freeze

      attr_reader :values, :provenance, :active_partition

      # Initializes a PlacardData value object.
      #
      # @param values [Hash{Symbol => Object}] initial field values
      # @param provenance [Hash{Symbol => Hash}] per-field provenance metadata
      # @param active_partition [Symbol] :none, :item, :collection, or :universal
      def initialize(values: {}, provenance: {}, active_partition: :none)
        @values = values.each_with_object({}) do |(k, v), acc|
          sym = k.to_sym
          acc[sym] = v if ALL_FIELDS.include?(sym)
        end.freeze

        @provenance = provenance.each_with_object({}) do |(k, meta), acc|
          sym = k.to_sym
          acc[sym] = meta.dup.freeze if ALL_FIELDS.include?(sym) && meta.is_a?(Hash)
        end.freeze

        @active_partition = active_partition
      end

      # Define direct reader methods for all 14 placard attributes
      ALL_FIELDS.each do |field|
        define_method(field) do
          @values[field]
        end
      end

      alias_method :name, :title

      # ------------------------------------------------------------------------
      # Partition Introspection (Ruby Metaprogramming)
      # ------------------------------------------------------------------------

      # Determines the partition (:item, :collection, :universal, or :none)
      # for a given domain instance or Class by inspecting its ancestor chain.
      #
      # @param source_or_class [Object, Class]
      # @return [Symbol]
      def self.partition_for(source_or_class)
        return :none if source_or_class.nil?

        klass = source_or_class.is_a?(Class) ? source_or_class : source_or_class.class
        ancestor_names = klass.ancestors.grep(Class).filter_map(&:name)

        return :universal if (ancestor_names & UNIVERSAL_CLASS_NAMES).any?
        return :item      if (ancestor_names & ITEM_CLASS_NAMES).any?
        return :collection if (ancestor_names & COLLECTION_CLASS_NAMES).any?

        :none
      end

      # Returns the subset of ALL_FIELDS permitted for `source_or_class`.
      #
      # @param source_or_class [Object, Class]
      # @return [Array<Symbol>]
      def self.allowed_fields_for(source_or_class)
        case partition_for(source_or_class)
        when :item       then ITEM_FIELDS
        when :collection then COLLECTION_FIELDS
        when :universal  then ALL_FIELDS
        else                  []
        end
      end

      def partition_for(source_or_class)
        self.class.partition_for(source_or_class)
      end

      def allowed_fields_for(source_or_class)
        self.class.allowed_fields_for(source_or_class)
      end

      # Asks whether this PlacardData (or an optional candidate source) is
      # operating on the ITEM field partition.
      def item_partition?(source_or_class = nil)
        target = source_or_class ? partition_for(source_or_class) : @active_partition
        %i[item universal].include?(target)
      end

      # Asks whether this PlacardData (or an optional candidate source) is
      # operating on the COLLECTION field partition.
      def collection_partition?(source_or_class = nil)
        target = source_or_class ? partition_for(source_or_class) : @active_partition
        %i[collection universal].include?(target)
      end

      # ------------------------------------------------------------------------
      # Functional Merge Pipeline
      # ------------------------------------------------------------------------

      # Merges attributes from `source` into a new PlacardData instance,
      # enforcing partition boundaries and updating provenance states.
      #
      # @param source [Object] domain instance (Photo, Portfolio, Exhibition, Item, or Placard)
      # @param raw_attrs [Hash] candidate attribute hash (falls back to `source.placard_attributes`)
      # @param status [Symbol] provenance status for newly applied fields (:direct, :intrinsic, :default)
      # @return [Gallery::Environ::PlacardData]
      def merge(source, raw_attrs = nil, status: :direct)
        raise ArgumentError, "Invalid provenance status: #{status}" unless VALID_STATUSES.include?(status)

        attrs = if !raw_attrs.nil?
                  raw_attrs
                elsif source.respond_to?(:placard_attributes)
                  source.placard_attributes
                else
                  {}
                end

        partition = partition_for(source)
        permitted = allowed_fields_for(source)

        new_values = @values.dup
        new_provenance = {}

        # Any existing value not overridden in this merge becomes :cascaded
        @provenance.each do |field, meta|
          new_provenance[field] = meta.merge(status: :cascaded)
        end

        source_class_name = source.is_a?(Class) ? source.name : source.class.name
        source_record_id  = source.respond_to?(:id) ? source.id : nil

        attrs.each do |key, val|
          field = key.to_sym
          next unless permitted.include?(field)
          next unless value_present?(val)

          new_values[field] = val
          new_provenance[field] = {
            status:       status,
            source_class: source_class_name,
            source_id:    source_record_id
          }
        end

        self.class.new(
          values:           new_values,
          provenance:       new_provenance,
          active_partition: partition
        )
      end

      # ------------------------------------------------------------------------
      # Provenance & Licensing Queries
      # ------------------------------------------------------------------------

      def provenance_for(field)
        @provenance[field.to_sym]
      end

      def direct?(field)
        provenance_for(field)&.fetch(:status, nil) == :direct
      end

      def cascaded?(field)
        provenance_for(field)&.fetch(:status, nil) == :cascaded
      end

      def intrinsic?(field)
        provenance_for(field)&.fetch(:status, nil) == :intrinsic
      end

      def default?(field)
        provenance_for(field)&.fetch(:status, nil) == :default
      end

      def present_field?(field)
        value_present?(@values[field.to_sym])
      end

      def source_label_for(field)
        meta = provenance_for(field)
        return nil unless meta

        base = meta[:source_class]
        meta[:source_id] ? "#{base}##{meta[:source_id]}" : base
      end

      # Resolves the Creative Commons license symbol key (defaults to :all_rights_reserved
      # when unset across the cascade).
      def cc_license_key
        raw = cc_license
        return :all_rights_reserved if raw.nil?
        return raw.to_sym if raw.is_a?(String) || raw.is_a?(Symbol)

        CcLicense::DICTIONARY.key(raw.to_i) || :all_rights_reserved
      end

      def cc_license_label
        CcLicense.label_for(cc_license_key)
      end

      def to_h
        ALL_FIELDS.each_with_object({}) do |field, acc|
          acc[field] = @values[field]
        end
      end

      private

      def value_present?(val)
        return false if val.nil?
        return !val.strip.empty? if val.is_a?(String)

        true
      end

    end   # class PlacardData
  end  # class environ
end  # module
