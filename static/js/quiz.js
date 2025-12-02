// static/js/quiz.js
(function () {
    const VERBOSE = true;
    function dbg(...args) {
        if (VERBOSE) console.log("[quiz]", ...args);
    }

    window.addEventListener("error", e =>
        console.error("[quiz] window error:", e.message, e.error || "")
    );
    window.addEventListener("unhandledrejection", e =>
        console.error("[quiz] unhandledrejection:", e.reason || "")
    );

    dbg("quiz.js loaded");

    // ---------- Cookies (DNI) ----------
    function setCookie(name, value, days) {
        let expires = "";
        if (typeof days === "number") {
            const d = new Date();
            d.setTime(d.getTime() + days * 86400000);
            expires = "; expires=" + d.toUTCString();
        }
        document.cookie =
            name +
            "=" +
            encodeURIComponent(value) +
            expires +
            "; path=/; SameSite=Lax";
    }
    function getCookie(name) {
        const nameEQ = name + "=";
        const parts = document.cookie.split(";");
        for (let c of parts) {
            c = c.trim();
            if (c.indexOf(nameEQ) === 0) {
                const v = decodeURIComponent(c.substring(nameEQ.length));
                dbg("getCookie", name, "=", v);
                return v;
            }
        }
        dbg("getCookie", name, "not found");
        return null;
    }
    function deleteCookie(name) {
        document.cookie =
            name +
            "=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/; SameSite=Lax";
    }

    // ---------- Theme + nav ----------
    function initThemeToggle() {
        const btn = document.getElementById("theme-toggle");
        if (!btn) return;

        const stored = localStorage.getItem("quiz_theme");
        if (stored === "dark") {
            document.body.classList.add("dark");
            btn.textContent = "☀️";
            dbg("Theme set to dark from storage");
        } else {
            btn.textContent = "🌙";
        }

        btn.addEventListener("click", () => {
            document.body.classList.toggle("dark");
            const isDark = document.body.classList.contains("dark");
            btn.textContent = isDark ? "☀️" : "🌙";
            localStorage.setItem("quiz_theme", isDark ? "dark" : "light");
            dbg("Theme toggled, now:", isDark ? "dark" : "light");
        });
    }
    function initNavButtons() {
        const home = document.getElementById("btn-home");
        const logout = document.getElementById("btn-logout");

        if (home) {
            home.addEventListener("click", () => {
                dbg("Home clicked");
                window.location.href = "/";
            });
        }
        if (logout) {
            logout.addEventListener("click", () => {
                dbg("Logout clicked");
                deleteCookie("quiz_dni");
                window.location.href = "/";
            });
        }
    }

    // ---------- State ----------
    let questionsContainer = null;
    let quizForm = null;
    let resultDiv = null;
    let testTitleElem = null;
    let currentTestId = null;
    let currentAttemptId = null;
    let currentDni = null;
    let currentQuestions = [];
    let quizInitialized = false;

    function showError(msg) {
        console.error("[quiz] ERROR:", msg);
        if (resultDiv) {
            resultDiv.textContent = msg;
            resultDiv.style.color = "var(--danger-color)";
        }
    }
    function clearResult() {
        if (resultDiv) {
            resultDiv.textContent = "";
            resultDiv.style.color = "";
        }
    }
    function getTestIdFromUrl() {
        const params = new URLSearchParams(window.location.search);
        const t = params.get("test_id");
        dbg("URL test_id =", t);
        return t;
    }

    // ---------- Build quiz UI ----------
// ---------- Build quiz UI ----------
    function ensureQuizUi() {
        // Use existing elements from HTML
        questionsContainer = document.getElementById("questions");
        quizForm = document.getElementById("quiz-form");
        resultDiv = document.getElementById("result");
        testTitleElem = document.getElementById("test-title");

        if (questionsContainer && quizForm && resultDiv && testTitleElem) {
            dbg("Using existing HTML elements");
            quizForm.addEventListener("submit", submitQuiz);
            return;
        }

        // Fallback: create elements if HTML doesn't have them
        dbg("Building quiz UI (fallback - HTML elements not found)");

        const page = document.querySelector(".page") || document.body;

        const card = document.createElement("div");
        card.className = "card";

        const h2 = document.createElement("h2");
        h2.id = "test-title";
        h2.textContent = "Test";

        const form = document.createElement("form");
        form.id = "quiz-form";

        const qDiv = document.createElement("div");
        qDiv.id = "questions";

        const actions = document.createElement("div");
        actions.style.marginTop = "0.8rem";

        const submitBtn = document.createElement("button");
        submitBtn.type = "submit";
        submitBtn.textContent = "Submit answers";

        actions.appendChild(submitBtn);

        const result = document.createElement("div");
        result.id = "result";
        result.style.marginTop = "0.6rem";

        form.appendChild(qDiv);
        form.appendChild(actions);
        form.appendChild(result);

        card.appendChild(h2);
        card.appendChild(form);
        page.appendChild(card);

        questionsContainer = qDiv;
        quizForm = form;
        resultDiv = result;
        testTitleElem = h2;

        quizForm.addEventListener("submit", submitQuiz);
    }

    // ---------- Backend calls ----------
    async function startTest(testId, dni) {
        dbg("startTest() BEGIN testId=", testId, "dni=", dni);
        clearResult();

        const url = `/tests/${encodeURIComponent(
            testId
        )}/start?student_dni=${encodeURIComponent(dni)}`;
        dbg("startTest() POST", url);

        const resp = await fetch(url, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: null,
        });

        const textBody = await resp.text();
        dbg("startTest() status", resp.status, "body =", textBody);

        if (!resp.ok) {
            throw new Error(
                "Error starting test (" + resp.status + "): " + textBody
            );
        }
        let data;
        try {
            data = JSON.parse(textBody);
        } catch (e) {
            console.error("[quiz] Invalid JSON from /start:", e, textBody);
            throw new Error("Invalid JSON from /start");
        }
        dbg("startTest() parsed data =", data);
        return data;
    }

    // ---------- Rendering ----------
    function renderQuestions(test) {
        dbg("renderQuestions()", test);

        if (!questionsContainer) return;
        questionsContainer.innerHTML = "";

        if (!test || !Array.isArray(test.questions) || !test.questions.length) {
            questionsContainer.textContent = "This test has no questions.";
            return;
        }

        currentQuestions = test.questions;
        dbg("Number of questions =", currentQuestions.length);

        test.questions.forEach((q, index) => {
            const qDiv = document.createElement("div");
            qDiv.className = "question";
            qDiv.dataset.questionId = String(q.id);

            const titleDiv = document.createElement("div");
            titleDiv.className = "question-title";
            titleDiv.innerHTML =
                `<span>${index + 1}</span>` + (q.question_text || q.text || "");
            qDiv.appendChild(titleDiv);

            const optsDiv = document.createElement("div");
            optsDiv.className = "options";

            const multiple =
                q.question_type === "multiple_choice" ||
                q.question_type === "multi" ||
                q.allow_multiple === true;

            const inputType = multiple ? "checkbox" : "radio";

            (q.options || []).forEach((opt) => {
                const optId = String(opt.id);
                const optText = opt.option_text || opt.text || "";

                const label = document.createElement("label");
                label.className = "option-label";
                label.dataset.questionId = String(q.id);
                label.dataset.optionId = optId;

                const input = document.createElement("input");
                input.type = inputType;
                input.name = `q_${q.id}`;
                input.value = optId;

                label.appendChild(input);
                label.appendChild(document.createTextNode(optText));
                optsDiv.appendChild(label);
            });

            qDiv.appendChild(optsDiv);
            questionsContainer.appendChild(qDiv);
        });
    }

    // ---------- Collect answers & feedback ----------
function collectAnswers() {
    dbg("collectAnswers()");

    const answers = [];
    let unanswered = 0;

    currentQuestions.forEach((q) => {
        const qId = q.id;
        const selector = `.option-label[data-question-id="${qId}"] input`;
        const inputs = questionsContainer
            ? questionsContainer.querySelectorAll(selector)
            : [];

        const selectedIds = [];

        inputs.forEach((input) => {
            const el = /** @type {HTMLInputElement} */ (input);
            if (el.checked) {
                const raw = el.value;
                const parsed = parseInt(raw, 10);

                if (Number.isNaN(parsed)) {
                    // This is the important change: never push NaN
                    dbg(
                        "collectAnswers(): NaN option id for question",
                        qId,
                        "raw value=",
                        raw
                    );
                } else {
                    selectedIds.push(parsed);
                }
            }
        });

        if (selectedIds.length === 0) {
            unanswered += 1;
        }

        // Backend expects an INTEGER, never null.
        // 0 will mean "no answer" (always wrong, but passes validation).
        const firstSelected = selectedIds.length > 0 ? selectedIds[0] : 0;

        answers.push({
            question_id: qId,
            selected_option_id: firstSelected,
            selected_option_ids: selectedIds,
        });
    });

    dbg("collectAnswers() -> answers payload:", answers);
    return answers;
    }

    function clearOptionFeedback() {
        if (!questionsContainer) return;
        const labels = questionsContainer.querySelectorAll(".option-label");
        labels.forEach((label) =>
            label.classList.remove("correct-option", "wrong-option")
        );
    }

    function applyFeedback(perQuestion) {
        dbg("applyFeedback()", perQuestion);
        clearOptionFeedback();

        if (!Array.isArray(perQuestion) || !perQuestion.length) return;

        perQuestion.forEach((item) => {
            const qId = item.question_id;

            const correctArray =
                item.correct_option_ids != null
                    ? item.correct_option_ids
                    : item.correct_option_id != null
                    ? [item.correct_option_id]
                    : [];
            const selectedArray =
                item.selected_option_ids != null
                    ? item.selected_option_ids
                    : item.selected_option_id != null
                    ? [item.selected_option_id]
                    : [];

            const correctIds = new Set(correctArray.map((x) => String(x)));
            const selectedIds = new Set(selectedArray.map((x) => String(x)));

            dbg(
                "applyFeedback(): qId=",
                qId,
                "correctIds=",
                Array.from(correctIds),
                "selectedIds=",
                Array.from(selectedIds)
            );

            const labels = questionsContainer.querySelectorAll(
                `.option-label[data-question-id="${qId}"]`
            );

            labels.forEach((label) => {
                const optId = label.dataset.optionId;
                const isCorrect = correctIds.has(optId);
                const isSelected = selectedIds.has(optId);

                if (isCorrect) label.classList.add("correct-option");
                if (!isCorrect && isSelected)
                    label.classList.add("wrong-option");
            });
        });
    }

    // ---------- Submit quiz ----------
    async function submitQuiz(event) {
        event.preventDefault();
        dbg("submitQuiz()");

        if (!currentTestId || !currentAttemptId) {
            showError("Test was not properly started.");
            return;
        }

        const answers = collectAnswers();
        if (!answers) return; // user cancelled because of unanswered

        try {
            const url = `/attempts/${encodeURIComponent(currentAttemptId)}/submit`;
            dbg("submitQuiz() POST", url, "payload:", {
                student_dni: currentDni,
                answers,
            });

            const resp = await fetch(url, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    student_dni: currentDni,
                    answers,
                }),
            });

            const textBody = await resp.text();
            dbg("submitQuiz() status", resp.status, "body =", textBody);

            if (!resp.ok) {
                throw new Error(
                    "Error submitting answers (" + resp.status + "): " + textBody
                );
            }

            let data;
            try {
                data = JSON.parse(textBody);
            } catch (e) {
                console.error("[quiz] Invalid JSON from /submit:", e, textBody);
                throw new Error("Invalid JSON from /submit");
            }

            dbg("submitQuiz() parsed data:", data);

            const score = data.score != null ? data.score.toFixed(2) : "?";
            const maxScore =
                data.max_score != null ? data.max_score.toFixed(2) : "?";
            const pct =
                data.percentage != null ? data.percentage.toFixed(1) + "%" : "?";

            if (resultDiv) {
                resultDiv.style.color = "";
                resultDiv.innerHTML =
                    `Result: <strong>${score}/${maxScore}</strong> ` +
                    `(${pct}) - status: ${data.status || "submitted"}.`;
            }
            // Hide submit button after submission
            const submitBtn = document.querySelector('#quiz-form button[type="submit"]');
            if (submitBtn) {
                submitBtn.style.display = "none";
            }

            // Disable all radio buttons (prevent changes after submit)
            const allInputs = document.querySelectorAll('#quiz-form input[type="radio"]');
            allInputs.forEach(input => input.disabled = true);

            const perQuestion = data.details || data.per_question || [];
            dbg("submitQuiz() perQuestion for feedback:", perQuestion);
            applyFeedback(perQuestion);
        } catch (e) {
            showError("Error submitting answers: " + e);
        }
    }

    // ---------- Init quiz ----------
    async function initQuiz() {
        if (quizInitialized) return;
        quizInitialized = true;

        dbg("initQuiz() start");
        ensureQuizUi();

        const testId = getTestIdFromUrl();
        if (!testId) {
            showError("Missing test_id in URL.");
            return;
        }
        currentTestId = testId;

        let dni = getCookie("quiz_dni");
        if (!dni) {
            const entered = window.prompt("Enter your ID (DNI) to start the test:");
            if (!entered || !entered.trim()) {
                alert("You must identify yourself with your DNI first.");
                window.location.href = "/";
                return;
            }
            dni = entered.trim();
            setCookie("quiz_dni", dni, 1);
        }
        currentDni = dni;
        dbg("Using DNI =", currentDni);

        try {
            const data = await startTest(testId, dni);
            
            // Check for error in response (e.g., max attempts reached)
            if (data.error) {
                showError(data.error);
                // Redirect back to portal after a delay
                setTimeout(() => {
                    window.location.href = "/";
                }, 3000);
                return;
            }
            
            currentAttemptId = data.attempt_id;
            dbg("Current attempt_id =", currentAttemptId);

            let test = null;

            if (data.test && Array.isArray(data.test.questions)) {
                dbg("initQuiz(): using embedded test from /start");
                test = data.test;
            } else if (Array.isArray(data.questions)) {
                dbg("initQuiz(): using top-level questions from /start");
                test = {
                    id: data.id || (data.test && data.test.id) || testId,
                    title:
                        data.title ||
                        (data.test && data.test.title) ||
                        "Test",
                    questions: data.questions,
                };
            } else {
                dbg("initQuiz(): no questions field, forcing empty");
                test = { id: testId, title: data.title || "Test", questions: [] };
            }

            if (!Array.isArray(test.questions)) {
                dbg(
                    "initQuiz(): test.questions not array; forcing []",
                    test.questions
                );
                test.questions = [];
            }

            if (testTitleElem) {
                testTitleElem.textContent =
                    test.title || `Test #${test.id || testId}`;
            }
            renderQuestions(test);
        } catch (e) {
            showError(String(e));
        }
    }

    document.addEventListener("DOMContentLoaded", () => {
        dbg("DOMContentLoaded on quiz page");
        initThemeToggle();
        initNavButtons();
        initQuiz();
    });
})();
