// Helper JS so we can autogen usernames
document.addEventListener("DOMContentLoaded", function () {
const button = document.getElementById("autogen_username");
if (!button) return;

button.addEventListener("click", function (event) {
    event.preventDefault();

    const name = document.getElementById("user_name").value;

    fetch("/admin/users/autogen_username?name=" + encodeURIComponent(name), {
    headers: {
        "Accept": "application/json"
    }
    })
    .then(response => response.json())
    .then(data => {
        document.getElementById("user_username").value = data.username;
    });
});
});
