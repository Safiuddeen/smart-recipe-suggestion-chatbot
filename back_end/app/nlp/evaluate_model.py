from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

# Import from your existing model file
from model import preprocess, texts, labels, TfidfVectorizer, LogisticRegression

# -----------------------------------
# Step 1: Preprocess data
# -----------------------------------
processed_texts = [preprocess(text) for text in texts]

# -----------------------------------
# Step 2: Convert text to vectors
# -----------------------------------
vectorizer = TfidfVectorizer(ngram_range=(1, 2), lowercase=True)
X = vectorizer.fit_transform(processed_texts)

# -----------------------------------
# Step 3: Split data
# -----------------------------------
X_train, X_test, y_train, y_test = train_test_split(
    X, labels, test_size=0.2, random_state=42
)

# -----------------------------------
# Step 4: Train model
# -----------------------------------
model = LogisticRegression(max_iter=3000)
model.fit(X_train, y_train)

# -----------------------------------
# Step 5: Predict
# -----------------------------------
y_pred = model.predict(X_test)

# -----------------------------------
# Step 6: Accuracy
# -----------------------------------
accuracy = accuracy_score(y_test, y_pred)

print("Accuracy:", accuracy)

# -----------------------------------
# Step 7: Detailed report (VERY IMPORTANT)
# -----------------------------------
print("\nClassification Report:\n") 
print(classification_report(y_test, y_pred))