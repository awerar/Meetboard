import functions = require('firebase-functions');
import admin = require('firebase-admin');
import firestore = require("@google-cloud/firestore")
admin.initializeApp();

const timoutSeconds = 5;

function generateActivityID() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789".split("");

    let id = "";
    for(let i = 0; i < 6; i++) id += chars[Math.floor(Math.random() * chars.length)];
    return id;
}

function getUserActivityDataFromActivity(activity: firestore.DocumentSnapshot) {
    return {
        name: activity.data()!.name,
        time: activity.data()!.time
    };
} 

function getUserActivityDataFromUserData(userData: firestore.DocumentSnapshot) {
    return {
        coming: userData.data()!.coming,
        role: userData.data()!.role
    };
}

function getUserActivityData(activity: firestore.DocumentSnapshot, userData: firestore.DocumentSnapshot) {
    return {
        ...getUserActivityDataFromActivity(activity),
        ...getUserActivityDataFromUserData(userData)
    };
}

async function isInTimeout(uid: string, context: functions.https.CallableContext) : Promise<boolean> {
    const privateDataRef = admin.firestore().collection("users").doc(uid).collection("private_data").doc("readonly");
    const privateDataSnapshot = await privateDataRef.get();

    const current_millis = Date.now();
    if (!privateDataSnapshot.exists ||
        !Object.values(privateDataSnapshot.data()!).includes("next_action_time") || 
    current_millis > (privateDataSnapshot.data()!.next_action_time as firestore.Timestamp).toMillis()) return false;
    else return true;
}

async function putInTimeout(uid: string) {
    const privateDataRef = admin.firestore().collection("users").doc(uid).collection("private_data").doc("readonly");
    const current_millis = Date.now();
    await privateDataRef.set({
        next_action_time: firestore.Timestamp.fromMillis(current_millis + timoutSeconds * 1000)
    }, {merge: true});
}

async function handleTimout(uid: string, context: functions.https.CallableContext) {
    if (!(await isInTimeout(uid, context))) await putInTimeout(uid);
    else throw new functions.https.HttpsError("permission-denied", `You need to wait more than ${timoutSeconds} seconds between actions.`);
}

exports.onUserAdded = functions.firestore.document("activities/{activity}/users/{userData}").onCreate(async (userDataSnapshot, context) => {
    const eventAgeMs = Date.now() - Date.parse(context.timestamp);
    const eventMaxAgeMs = 1000 * 10;
    if (eventAgeMs > eventMaxAgeMs) {
        console.log("Dropped event");
        return "Dropped";
    }

    const uid = userDataSnapshot.id;
    const userDataRef = userDataSnapshot.ref;
    const activityRef = userDataSnapshot.ref.parent.parent!;
    const activityID = activityRef.id;
    const privateUserDataRef = admin.firestore().collection("users").doc(uid).collection("private_data").doc("user_activities");
    const userActivityRef = privateUserDataRef.collection("user_activities").doc(activityID);

    await admin.firestore().runTransaction(async transaction => {
        const userData = await transaction.get(userDataRef);
        const activity = await transaction.get(activityRef);

        const activityUpdateData = {};
        //@ts-ignore
        activityUpdateData["users." + uid] = userData.data();
        transaction.update(activityRef, activityUpdateData);

        transaction.update(privateUserDataRef, {
            activities: firestore.FieldValue.arrayUnion(activityID),
            activity_count: firestore.FieldValue.increment(1)
        });

        transaction.create(userActivityRef, getUserActivityData(activity, userData));
    });

    //Transaction succeeded
    return "Done";
});

exports.onUserRemoved = functions.firestore.document("activities/{activity}/users/{userData}").onDelete(async (userData, context) => {
    const eventAgeMs = Date.now() - Date.parse(context.timestamp);
    const eventMaxAgeMs = 1000 * 10;
    if (eventAgeMs > eventMaxAgeMs) {
        console.log("Dropped event");
        return "Dropped";
    }

    const uid = userData.id;
    const activityRef = userData.ref.parent.parent!;
    const activityID = activityRef.id;
    const privateUserDataRef = admin.firestore().collection("users").doc(uid).collection("private_data").doc("user_activities");
    const userActivityRef = privateUserDataRef.collection("user_activities").doc(activityID);

    await admin.firestore().runTransaction(async transaction => {
        const otherDocuments = (await transaction.get(activityRef.collection("users"))).docs;
        const usersLeft: Number = otherDocuments.length;
        //Delete activity
        if (usersLeft === 0) transaction.delete(activityRef);
        else {
            //Remove user from activity map
            const activityUpdateData = {};
            //@ts-ignore
            activityUpdateData["users." + uid] = firestore.FieldValue.delete();
            transaction.update(activityRef, activityUpdateData);
        }
    
        //Remove activity data from users private_data
        transaction.update(privateUserDataRef, {
            activity_count: firestore.FieldValue.increment(-1),
            activities: firestore.FieldValue.arrayRemove(activityID)
        });
    
        //Remove the userActivity
        transaction.delete(userActivityRef);
    
        //If user is the owner, remove all other users aswell
        if (userData.data().role === "owner") {
            otherDocuments.forEach(d => {
                transaction.delete(d.ref);
            });
        }
    });

    //Transaction success
    return "Done";

});

exports.onUserDataChanged = functions.firestore.document("activities/{activity}/users/{userData}").onUpdate((userData, context) => {
    const uid = userData.after.id;
    const activityRef = userData.after.ref.parent.parent!;
    const activityID = activityRef.id;
    const privateUserDataRef = admin.firestore().collection("users").doc(uid).collection("private_data").doc("user_activities");
    const userActivityRef = privateUserDataRef.collection("user_activities").doc(activityID);

    const batch = admin.firestore().batch();
    batch.update(userActivityRef, getUserActivityDataFromUserData(userData.after));

    const activityUpdateData = {};
    //@ts-ignore
    activityUpdateData["users." + userData.after.id] = userData.after.data();
    batch.update(activityRef, activityUpdateData);

    return batch.commit();
});

exports.onActivityChanged = functions.firestore.document("activities/{activity}").onUpdate((activity, context) => {
    const updateData = getUserActivityDataFromActivity(activity.after);
    const activityID = activity.after.id;

    const batch = admin.firestore().batch();
    Object.keys((activity.after.data().users as Object)).forEach(uid => {
        const userActivityRef = admin.firestore().collection("users").doc(uid).collection("private_data").doc("user_activities").collection("user_activities").doc(activityID);
        batch.update(userActivityRef, updateData);
    });

    return batch.commit();
});

//NOTE: userActivity is implicitly added
exports.createActivity = functions.https.onCall(async (data, context) => {
    if (context.auth === undefined || context.auth === null) throw new functions.https.HttpsError("unauthenticated", "Only a signed in user can call this function.");
    const uid: string = context.auth.uid;

    await handleTimout(uid, context);

    if (data === null) throw new functions.https.HttpsError("invalid-argument", "No activity data specified.");
    if (!(typeof data.time === "number" && typeof data.name === "string")) throw new functions.https.HttpsError("invalid-argument", `Invalid activity data: time is ${typeof data.time} and should be number, name is ${typeof data.name} and should be string`);
    data.time = firestore.Timestamp.fromMillis(data.time);

    const privateDataRef = admin.firestore().collection("users").doc(uid).collection("private_data").doc("user_activities");
    const privateData = await privateDataRef.get();

    if (privateData.data()!.activity_count > 1000) throw new functions.https.HttpsError("resource-exhausted", "Can't create more than 1000 activities.");

    const batch = admin.firestore().batch();

    const activityRef = admin.firestore().collection("activities").doc(generateActivityID());
    batch.set(activityRef, {
        ...data,
    });

    const userDataRef = activityRef.collection("users").doc(uid);
    batch.set(userDataRef, {
        role: "owner",
        coming: true
    });

    await batch.commit();

    return activityRef.id;
});

exports.joinActivity = functions.https.onCall(async (data, context) => {
    if (context.auth === null || context.auth === undefined) throw new functions.https.HttpsError("unauthenticated", "Only a signed in user can join an activity.");
    const uid: string = context.auth.uid;

    await handleTimout(uid, context);

    if (data === null) throw new functions.https.HttpsError("invalid-argument", "No activity data specified.");
    if (typeof data.id !== "string") throw new functions.https.HttpsError("invalid-argument", `Invalid id: id is not a string, but a ${typeof data.id}`);

    const activityRef = admin.firestore().collection("activities").doc(data.id);
    const activitySnapshot = await activityRef.get();
    if (!activitySnapshot.exists) throw new functions.https.HttpsError("not-found", `There exists no activity with id ${data.id}`);

    await activityRef.collection("users").doc(uid).create({
        role: "participant",
        coming: true
    });

    return "Done";
});

exports.inviteToActivity = functions.https.onCall(async (data, context) => {
    if (context.auth === null || context.auth === undefined) throw new functions.https.HttpsError("unauthenticated", "Only a signed in user can invite people.");
    const uid: string = context.auth.uid;

    await handleTimout(uid, context);

    if (typeof data.id !== "string" || typeof data.uid !== "string") throw new functions.https.HttpsError("invalid-argument", `One or more arguments are of the wrong type`);
    const otherUID: string = data.uid;
    const activityID: string = data.id;

    const otherUserRef = admin.firestore().collection("users").doc(otherUID);
    const otherUserSnapshot = await otherUserRef.get();
    if (!otherUserSnapshot.exists) throw new functions.https.HttpsError("not-found", `No user found with id ${otherUID}`);

    const userActivityRef = admin.firestore().collection("users").doc(uid).collection("private_data").doc("user_activities").collection("user_activities").doc(activityID);
    const userActivitySnapshot = await userActivityRef.get();
    if (!userActivitySnapshot.exists || userActivitySnapshot.data()!.role !== "owner") throw new functions.https.HttpsError("not-found", `You are not owner of any activities with id ${activityID}`);

    const otherUserPrivateDataRef = otherUserRef.collection("private_data").doc("user_activities");
    const otherUserPrivateDataSnapshot = await otherUserPrivateDataRef.get();
    if ((otherUserPrivateDataSnapshot.data()!.activities as string[]).includes(activityID)) throw new functions.https.HttpsError("already-exists", `User ${otherUID} already is part of activity ${activityID}.`);

    await admin.firestore().collection("activities").doc(activityID).collection("users").doc(otherUID).create({
        role: "participant",
        coming: true
    });

    return true;
});

exports.activityExists = functions.https.onCall(async (data, context) => {
    if (context.auth === null || context.auth === undefined) throw new functions.https.HttpsError("unauthenticated", "Only a signed in user can check if an activity exists");
    if (typeof data.id !== "string") throw new functions.https.HttpsError("invalid-argument", "'id' needs to be a string.");

    const docRef = admin.firestore().collection("activities").doc(data.id);
    const doc = await docRef.get();

    return doc.exists;
});