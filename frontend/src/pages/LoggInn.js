import React, { useState } from "react";
import { useNavigate } from "react-router-dom";

const LoggInn = () => {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const navigate = useNavigate();

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const response = await fetch("/api/auth/login", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ email, password }),
            });
            const data = await response.json();
            if (data.success) {
                localStorage.setItem("token", data.token);
                navigate("/oversikt");
            } else {
                alert("Feil e-post eller passord");
            }
        } catch (error) {
            alert("Serverfeil, prøv igjen.");
        }
    };

    return (
        <div>
            <h2>Logg Inn</h2>
            <form onSubmit={handleSubmit}>
                <input type="email" placeholder="E-post" value={email} onChange={(e) => setEmail(e.target.value)} required />
                <input type="password" placeholder="Passord" value={password} onChange={(e) => setPassword(e.target.value)} required />
                <button type="submit">Logg Inn</button>
            </form>
        </div>
    );
};

export default LoggInn;