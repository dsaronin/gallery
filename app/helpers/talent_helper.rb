module TalentHelper
  def exact_age(dob)
    return "—" if dob.blank?

    today = Date.current
    age = today.year - dob.year
    age -= 1 if today < dob + age.years

    "#{age} yrs old"
  end
end
