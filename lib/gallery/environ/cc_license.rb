# frozen_string_literal: true

# Gallery: 
# Copyright (c) 2026 David S Anderson, All Rights Reserved
#
# class CcLicense -- Domain taxonomy & licensing container

module Gallery
  class Environ
    class CcLicense
      DICTIONARY = {
        all_rights_reserved: 0,
        cc_by:               1,
        cc_by_sa:            2,
        cc_by_nc:            3,
        cc_by_nc_sa:         4,
        cc_by_nd:            5,
        cc_by_nc_nd:         6,
        public_domain:       7
      }.freeze

      LABELS = {
        all_rights_reserved: "All Rights Reserved",
        cc_by:               "Creative Commons Attribution (CC BY 4.0)",
        cc_by_sa:            "Creative Commons Attribution-ShareAlike (CC BY-SA 4.0)",
        cc_by_nc:            "Creative Commons Attribution-NonCommercial (CC BY-NC 4.0)",
        cc_by_nc_sa:         "Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA 4.0)",
        cc_by_nd:            "Creative Commons Attribution-NoDerivatives (CC BY-ND 4.0)",
        cc_by_nc_nd:         "Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND 4.0)",
        public_domain:       "Public Domain / CC0"
      }.freeze

      URLS = {
        all_rights_reserved: nil,
        cc_by:               "https://creativecommons.org/licenses/by/4.0/",
        cc_by_sa:            "https://creativecommons.org/licenses/by-sa/4.0/",
        cc_by_nc:            "https://creativecommons.org/licenses/by-nc/4.0/",
        cc_by_nc_sa:         "https://creativecommons.org/licenses/by-nc-sa/4.0/",
        cc_by_nd:            "https://creativecommons.org/licenses/by-nd/4.0/",
        cc_by_nc_nd:         "https://creativecommons.org/licenses/by-nc-nd/4.0/",
        public_domain:       "https://creativecommons.org/publicdomain/zero/1.0/"
      }.freeze

      def self.label_for(key)
        LABELS[key.to_s.to_sym] || "Unknown License"
      end

      def self.url_for(key)
        URLS[key.to_s.to_sym]
      end

      def self.options_for_select
        DICTIONARY.keys.map { |k| [label_for(k), k.to_s] }
      end

    end  # CLASS
  end  # CLASS
end  # MODULE
