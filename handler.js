const jwt = require('jsonwebtoken');

const AUTH0_CLIENT_ID = process.env.auth0_client_id;
const AUTH0_CLIENT_SECRET = process.env.auth0_client_secret;

// Policy helper function
const generatePolicy = (principalId, effect, resource) => {
    const authResponse = {};
    authResponse.principalId = principalId;
    if (effect && resource) {
        const policyDocument = {};
        policyDocument.Version = '2012-10-17';
        policyDocument.Statement = [];
        const statementOne = {};
        statementOne.Action = 'execute-api:Invoke';
        statementOne.Effect = effect;
        statementOne.Resource = resource;
        policyDocument.Statement[0] = statementOne;
        authResponse.policyDocument = policyDocument;
    }
    return authResponse;
};

module.exports.auth = (event, context, cb) => {
    if (event.authorizationToken) {
        // remove "bearer " from token
        const token = event.authorizationToken.substring(7);
        const options = {
            audience: AUTH0_CLIENT_ID,
        };

        jwt.verify(token, AUTH0_CLIENT_SECRET, options, (err, decoded) => {
            if (err) {
                cb('Unauthorized');
            } else {a
                var response = generatePolicy(decoded.sub, 'Allow', event.methodArn);
                response.context = {};
                response.context.email = decoded.email;
                cb(null, response);
            }
        });
    }
    else {
        cb('Unauthorized');
    }
};