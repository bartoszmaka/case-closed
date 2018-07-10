require 'rails_helper'

describe LockProperty do
  context 'property is available' do
    it 'locks property' do
      freeze_time do
        property = create(:property)

        LockProperty.call(
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
          lock_token: 'my_lock_token'
        )

        expect(property.locks.last).to_have_attributes(
          lock_token: 'my_lock_token',
          locked_at: Time.now,
          check_in_date: Date.new(2018, 6, 6),
          check_out_date: Date.new(2018, 6, 10)
        )
      end
    end
  end

  context 'when new reservation overlaps already existing reservation' do
    context 'when check_in_date overlaps' do
      it 'raises PropertyBookedException' do
        property = create(:property)
        create(
          :reservation,
          check_in_date: '2018-06-05',
          check_out_date: '2018-06-12',
          property: property
        )

        expect do
          LockProperty.call(
            id: property.id,
            check_in_date: '2018-06-06',
            check_out_date: '2018-06-19',
          )
        end.to raise_exception(PropertyBookedException)
      end
    end

    context 'when check_out_date overlaps' do
      it 'raises PropertyBookedException' do
        property = create(:property)
        create(
          :reservation,
          check_in_date: '2018-06-05',
          check_out_date: '2018-06-12',
          property: property
        )

        expect do
          LockProperty.call(
            id: property.id,
            check_in_date: '2018-06-01',
            check_out_date: '2018-06-10',
          )
        end.to raise_exception(PropertyBookedException)
      end
    end

    context 'when both dates overlaps' do
      it 'raises PropertyBookedException' do
        property = create(:property)
        create(
          :reservation,
          check_in_date: '2018-06-05',
          check_out_date: '2018-06-12',
          property: property
        )

        expect do
          LockProperty.call(
            id: property.id,
            check_in_date: '2018-06-01',
            check_out_date: '2018-06-31',
          )
        end.to raise_exception(PropertyBookedException)
      end
    end

    context 'when both are within existing reservation' do
      it 'raises PropertyBookedException' do
        property = create(:property)
        create(
          :reservation,
          check_in_date: '2018-06-05',
          check_out_date: '2018-06-12',
          property: property
        )

        expect do
          LockProperty.call(
            id: property.id,
            check_in_date: '2018-06-06',
            check_out_date: '2018-06-10',
          )
        end.to raise_exception(PropertyBookedException)
      end
    end
  end

  context 'when property is locked by somebody else in given dates' do
    context 'when check_in_date overlaps' do
      it 'raises PropertyLockedException' do
        property = create(:property)
        create(
          :lock,
          lock_token: 'somebody_else_lock_token'
          locked_at: 1.minute.ago
          check_in_date: '2018-06-05',
            check_out_date: '2018-06-12',
            property: property
        )

        expect do
          LockProperty.call(
            id: property.id,
            check_in_date: '2018-06-06',
            check_out_date: '2018-06-19',
            lock_token: 'my_lock_token'
          )
        end.to raise_exception(PropertyLockedException)
      end
    end

    context 'when check_out_date overlaps' do
      it 'raises PropertyLockedException' do
        property = create(:property)
        create(
          :lock,
          lock_token: 'somebody_else_lock_token'
          locked_at: 1.minute.ago
          check_in_date: '2018-06-05',
            check_out_date: '2018-06-12',
            property: property
        )

        expect do
          LockProperty.call(
            id: property.id,
            check_in_date: '2018-06-01',
            check_out_date: '2018-06-10',
            lock_token: 'my_lock_token'
          )
        end.to raise_exception(PropertyLockedException)
      end
    end

    context 'when both dates overlaps' do
      it 'raises PropertyLockedException' do
        property = create(:property)
        create(
          :lock,
          lock_token: 'somebody_else_lock_token'
          locked_at: 1.minute.ago
          check_in_date: '2018-06-05',
            check_out_date: '2018-06-12',
            property: property
        )

        expect do
          LockProperty.call(
            id: property.id,
            check_in_date: '2018-06-01',
            check_out_date: '2018-06-31',
            lock_token: 'my_lock_token'
          )
        end.to raise_exception(PropertyLockedException)
      end
    end

    context 'when both are within existing reservation' do
      it 'raises PropertyLockedException' do
        property = create(:property)
        create(
          :lock,
          lock_token: 'somebody_else_lock_token'
          locked_at: 1.minute.ago
          check_in_date: '2018-06-05',
            check_out_date: '2018-06-12',
            property: property
        )

        expect do
          LockProperty.call(
            id: property.id,
            check_in_date: '2018-06-06',
            check_out_date: '2018-06-10',
            lock_token: 'my_lock_token'
          )
        end.to raise_exception(PropertyLockedException)
      end
    end

    context 'when lock does not overlap other locks' do
      it 'locks property' do
        freeze_time do
          property = create(:property)
          create(
            :lock,
            lock_token: 'somebody_else_lock_token'
            locked_at: 1.minute.ago
            check_in_date: '2018-06-01',
              check_out_date: '2018-06-03',
              property: property
          )

          LockProperty.call(
            id: property.id,
            check_in_date: '2018-06-06',
            check_out_date: '2018-06-10',
            lock_token: 'my_lock_token'
          )

          expect(property.locks.last).to_have_attributes(
            lock_token: 'my_lock_token',
            locked_at: Time.now,
            check_in_date: Date.new(2018, 6, 1),
            check_out_date: Date.new(2018, 6, 3)
          )
        end
      end
    end
  end

  context 'when property lock expired' do
    it 'locks property' do
      freeze_time do
        property = create(:property)
        create(
          :lock,
          lock_token: 'somebody_else_lock_token'
          locked_at: 15.minute.ago
          check_in_date: '2018-06-05',
            check_out_date: '2018-06-12',
            property: property
        )

        LockProperty.call(
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
          lock_token: 'my_lock_token'
        )

        expect(property.locks.last).to_have_attributes(
          lock_token: 'my_lock_token',
          locked_at: Time.now,
          check_in_date: Date.new(2018, 6, 5),
          check_out_date: Date.new(2018, 6, 12)
        )
      end
    end
  end

  context 'when property was locked by the same user' do
    it 'locks property' do
      freeze_time do
        property = create(:property)
        create(
          :lock,
          lock_token: 'my_lock_token'
          locked_at: 1.minute.ago
          check_in_date: '2018-06-05',
            check_out_date: '2018-06-12',
            property: property
        )

        LockProperty.call(
          id: property.id,
          check_in_date: '2018-06-06',
          check_out_date: '2018-06-10',
          lock_token: 'my_lock_token'
        )

        expect(property.locks.last).to_have_attributes(
          lock_token: 'my_lock_token',
          locked_at: Time.now,
          check_in_date: Date.new(2018, 6, 5),
          check_out_date: Date.new(2018, 6, 12)
        )
      end
    end
  end
end

