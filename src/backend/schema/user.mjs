import mongoose from 'mongoose';

import Roles from './roles-enum';

/**
 * User of the eureka platform
 * Model is used for the local user authentication with passport
 */
const userSchema = mongoose.Schema(
  {
    username: {
      type: String,
      required: true,
      unique: true
    },
    password: {
      type: String,
      required: true,
      unique: false
    },
    email: {
      type: String,
      required: true,
      unique: true
    },
    isEditor: {
      type: Boolean,
    },
    roles: [{
      type: String,
      enum: Object.values(Roles),
    }]
  },
  {collection: 'users'}
);




export default userSchema;
