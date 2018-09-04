import AddressBook from '../schema/address-book.mjs';
import errorThrower from '../helpers/error-thrower.mjs';

export default {
  getContacts: async (address) => {
    const contacts = await AddressBook.find({addressBookOwnerAddress: address});
    if (!contacts)
      errorThrower.internalError();
    else
      return contacts;
  },

  createContact: async (addressBookOwnerAddress,
                  {
                    contactAddress,
                    preName,
                    lastName,
                    info
                  }) => {

    let contact = await AddressBook.findOne({
      addressBookOwnerAddress: addressBookOwnerAddress,
      contactAddress: contactAddress
    });

    if (contact)
      errorThrower.entryAlreadyExists();
    else {
      contact = new AddressBook({
        addressBookOwnerAddress: addressBookOwnerAddress,
        contactAddress: contactAddress,
        preName: preName,
        lastName: lastName,
        info: info
      });
      const dbcontact = await contact.save();
      if (!dbcontact) errorThrower.noCreationOfEntry();
      return dbcontact;
    }
  },

  updateContact: async (addressBookOwnerAddress,
                        {
                          contactAddress,
                          preName,
                          lastName,
                          info
                        }) => {

    let contact = await AddressBook.findOne({
      addressBookOwnerAddress: addressBookOwnerAddress,
      contactAddress: contactAddress
    });

    if (!contact)
      errorThrower.noEntryFoundByParameters();
    else {
      return await AddressBook.findOneAndUpdate(
        {
          addressBookOwnerAddress: addressBookOwnerAddress,
          contactAddress: contactAddress
        },
        {
          preName: preName,
          lastName: lastName,
          info: info
        });
    }
  },

  deleteContact: async (addressBookOwnerAddress, contactAddress) => {
    const contact = await AddressBook.findOne({
      addressBookOwnerAddress: addressBookOwnerAddress,
      contactAddress: contactAddress
    });
    if (!contact)
      errorThrower.noEntryFoundByParameters();
    else
      return await contact.remove();
  }
};
