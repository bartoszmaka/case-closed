require 'rails_helper'

describe 'ReservationFlow' do
  scenario 'user books a property' do

    create(:property, name: 'amazing_house', description: 'amazing_description')
    create(:property, name: 'some_other_house', description: 'some_other_description')

    behavior 'user browser properties', using: 'PropertiesController#index' do
      visit '/properties'

      expect(page).to have_row_content('Full name' => 'Luke Cage')
      expect(page).to have_row_content('Full name' => 'Jessica Jones')
    end

    behavior 'user checks details of selected house', using: 'PropertiesController#show' do
      click_link 'amazing_house'

      expect(page).to have_css('p', :text => 'amazing_house')
      expect(page).to have_css('p', :text => 'amazing_description')
    end

    behaviour 'user checks availability of selected houd', using: 'ReservationController#check_availability' do
      fill_in('Check In Date', with: '2018-06-06')
      fill_in('Check Out Date', with: '2018-06-10')

      click_button 'Book property'

      expect(page).to have_css('p', :text => 'Finalize reservation screen')
    end

    behaviour 'user finializes property reservation', using: 'ReservationController#new' do
      fill_in('Firstname', with: 'Bob')
      fill_in('Lastname', with: 'Rspec')
      fill_in('Email', with: 'bob@rspec.com')

      click_button 'Finalize'

      expect(page).to have_content('Property sucessfully booked')
    end
  end

