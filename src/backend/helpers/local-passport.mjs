import passport from 'passport';
import passportLocal from 'passport-local/lib/index';
import bcryptHasher from './bcrypt-hasher';
import User from '../schema/user';

const LocalStrategy = passportLocal.Strategy;

passport.use(
  new LocalStrategy(async function(username, password, done) {
    const dbUser = await User.findOne({username: username});
    const isCorrectHash = await bcryptHasher.compare(password, dbUser.password);

    User.findOne(
      {
        username: username
      },
      function(err, user) {
        if (err) {
          return done(err);
        }

        // no user found
        if (!user) {
          return done(null, false);
        }

        // incorrect password
        if (!isCorrectHash) {
          return done(null, false);
        }

        //login success
        return done(null, user);
      }
    );
  })
);

/**
 *  Configure Passport authenticated session persistence.
 */
passport.serializeUser(function(user, done) {
  done(null, user._id);
});

passport.deserializeUser(function(user_id, done) {
  done(null, user_id);
});

export default passport;
