require 'rails_helper'

describe ReservationsController do
  describe '#check_availability' do
    context 'when property is available' do
      it 'redirects to new reservation' do
        allow(Lock).to receive(:generate_lock_token).and_return('lock_token')
        allow(LockProperty).to reveice(:call)
        property = create(:property)

        get :check_availability, params: {
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
        }

        expect(LockProperty).to have_received(:call).with(
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
          lock_token: 'lock_token'
        )
        expect(response).to redirect_to(new_reservation_path)
        expect(session[:lock_token]).to eq 'lock_token'
      end
    end

    context 'when property is already reserved' do
      it 'redirects to property with proper flash message' do
        allow(LockProperty).to reveice(:call).and_raise_exception(PropertyLockedException)
        allow(Lock).to receive(:generate_lock_token).and_return('lock_token')
        property = create(:property)

        get :check_availability, params: {
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
        }

        expect(LockProperty).to have_received(:call).with(
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
          lock_token: 'lock_token'
        )
        expect(response).to redirect_to(property_path(property.id))
        expect(flash[:error]).to eq 'This property is already booked at this period of time'
      end
    end

    context 'when property is being booked' do
      it 'redirects to property with proper flash message' do
        stub_env('SOFT_LOCK_DELAY', 5)
        allow(LockProperty).to reveice(:call).and_raise_exception(PropertyBookedException)
        allow(Lock).to receive(:generate_lock_token).and_return('lock_token')
        property = create(:property)

        get :check_availability, params: {
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
        }

        expect(LockProperty).to have_received(:call).with(
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
          lock_token: 'lock_token'
        )
        expect(response).to redirect_to(property_path(property.id))
        expect(flash[:error]).to eq 'This property is being booked by somebody else. Please wait 5 minutes and try again'
      end
    end
  end

  describe '#create' do
    context 'when no conflicting reservation were created in the meantime' do
      it 'creates a reservation' do
        allow(LockProperty).to reveice(:call)
        property = create(:property)
        params = {
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
          firstname: 'Bob',
          lastname: 'Rspec',
          email: 'bob@rspec.com'
        }

        post :create, params: params, session: { lock_token: 'lock_token' }

        expect(LockProperty).to have_received(:call).with(
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
          lock_token: 'lock_token'
        )
        expect(Reservation.last).to have_attributes(
          firstname: 'Bob',
          lastname: 'Rspec',
          email: 'bob@rspec.com',
          property_id: property.id
          check_in_date: DateTime.new(2018, 06, 06),
          check_out_date: DateTime.new(2018, 06, 10),
          )
      end
    end

    context 'when conflicting reservation was created in the meantime' do
      it 'redirects to property path with proper flash message' do
        allow(LockProperty).to reveice(:call).and_raise_exception(PropertyBookedException)
        property = create(:property)
        params = {
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
          firstname: 'Bob',
          lastname: 'Rspec',
          email: 'bob@rspec.com'
        }

        post :create, params: params, session: { lock_token: 'lock_token' }

        expect(LockProperty).to have_received(:call).with(
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
          lock_token: 'lock_token'
        )
        expect(response).to redirect_to(property_path(property.id))
        expect(flash[:error]).to eq 'This property was booked by somebody else in the meantime'
      end
    end
  end
end
