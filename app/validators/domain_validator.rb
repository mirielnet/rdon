# frozen_string_literal: true

class DomainValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value.is_a?(String)

    domain = begin
      if options[:acct]
        value.split('@')[1]
      else
        value
      end
    end

    return if value.blank?

    record.errors.add(attribute, I18n.t('domain_validator.invalid_domain')) unless compliant?(domain)
  end

  private

  def compliant?(value)
    value.match?(Twitter::TwitterText::Regex[:valid_domain])
  end
end
