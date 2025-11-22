import firebase_admin
from firebase_admin import credentials, firestore

# Connect to shared Firebase project
cred = credentials.Certificate("test_beach_circle_key.json") #this is temp database for testing
firebase_admin.initialize_app(cred)

db = firestore.client()

#add a name and email to demo_test_users table :D
def add_user(name, email): 
    db.collection("demo_test_users").add({
        "name": name,
        "email": email,
        "createdAt": firestore.SERVER_TIMESTAMP
    })
    print(f"Added {name} ({email})")

#fetch the data frm firebase and print all entries
def list_users():
    users = db.collection("demo_test_users").get()
    print("\nCurrent users in Firestore:")
    for user in users:
        user_data = user.to_dict()
        print(f"Name: {user_data['name']} \nEmail: {user_data['email']}\n")

if __name__ == "__main__":
    list_users()
    name = input("Enter your name: ")
    email = input("Enter your email: ")
    add_user(name, email)
    list_users()