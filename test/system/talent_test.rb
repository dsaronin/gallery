require "application_system_test_case"

class TalentTest < ApplicationSystemTestCase
  setup do
    @talent = talents(:one)
  end

  test "visiting the index" do
    visit talent_url
    assert_selector "h1", text: "Talents"
  end

  test "should create talent" do
    visit talent_url
    click_on "New talent"

    click_on "Create Talent"

    assert_text "Talent was successfully created"
    click_on "Back"
  end

  test "should update Talent" do
    visit talent_url(@talent)
    click_on "Edit this talent", match: :first

    click_on "Update Talent"

    assert_text "Talent was successfully updated"
    click_on "Back"
  end

  test "should destroy Talent" do
    visit talent_url(@talent)
    click_on "Destroy this talent", match: :first

    assert_text "Talent was successfully destroyed"
  end
end
