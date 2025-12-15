// question-bank.js - Question Bank Management

(function () {
    const VERBOSE = true;
    function dbg(...args) {
        if (VERBOSE) console.log("[question-bank]", ...args);
    }

    dbg("question-bank.js loaded");

    // ---------- Cookie helpers ----------
    function getCookie(name) {
        const nameEQ = name + "=";
        const ca = document.cookie.split(";");
        for (let c of ca) {
            c = c.trim();
            if (c.indexOf(nameEQ) === 0) {
                return decodeURIComponent(c.substring(nameEQ.length));
            }
        }
        return null;
    }

    // ---------- Theme handling ----------
    function initTheme() {
        const btn = document.getElementById("theme-toggle");
        if (!btn) return;

        const stored = localStorage.getItem("quiz_theme");
        if (stored === "dark") {
            document.body.classList.add("dark");
            btn.textContent = "☀️";
        } else {
            btn.textContent = "🌙";
        }

        btn.addEventListener("click", () => {
            document.body.classList.toggle("dark");
            const isDark = document.body.classList.contains("dark");
            btn.textContent = isDark ? "☀️" : "🌙";
            localStorage.setItem("quiz_theme", isDark ? "dark" : "light");
        });
    }

    // ---------- Navigation ----------
    function initNavigation() {
        const homeBtn = document.getElementById("btn-home");
        const dashboardBtn = document.getElementById("btn-dashboard");

        if (homeBtn) {
            homeBtn.addEventListener("click", () => {
                window.location.href = "/";
            });
        }
        if (dashboardBtn) {
            dashboardBtn.addEventListener("click", () => {
                window.location.href = "/dashboard";
            });
        }
    }

    // ---------- Version footer ----------
    async function loadVersion() {
        try {
            const resp = await fetch("/version");
            if (resp.ok) {
                const data = await resp.json();
                const versionText = document.getElementById("version-text");
                if (versionText) {
                    versionText.textContent = `Version: ${data.version || "unknown"}`;
                }
            }
        } catch (e) {
            dbg("Failed to load version", e);
        }
    }

    // ---------- State ----------
    let teacherDni = null;
    let courses = [];
    let questions = [];
    let selectedCourseId = null;
    let editingQuestionId = null;
    let deleteQuestionId = null;
    let deleteQuestionUsedInTests = [];

    // Pagination
    let currentPage = 1;
    const questionsPerPage = 10;

    // ---------- DOM References ----------
    const errorDiv = document.getElementById("error");
    const accessDenied = document.getElementById("access-denied");
    const mainContent = document.getElementById("main-content");
    const courseSelect = document.getElementById("course-select");
    const btnNewCourse = document.getElementById("btn-new-course");
    const newCourseForm = document.getElementById("new-course-form");
    const newCourseCode = document.getElementById("new-course-code");
    const newCourseName = document.getElementById("new-course-name");
    const btnSaveCourse = document.getElementById("btn-save-course");
    const btnCancelCourse = document.getElementById("btn-cancel-course");
    const courseFormError = document.getElementById("course-form-error");

    const jsonFileInput = document.getElementById("json-file");
    const replaceQuestionsCheckbox = document.getElementById("replace-questions");
    const btnUploadJson = document.getElementById("btn-upload-json");
    const uploadResult = document.getElementById("upload-result");

    const btnDownloadJson = document.getElementById("btn-download-json");
    const downloadResult = document.getElementById("download-result");

    const questionsEmpty = document.getElementById("questions-empty");
    const questionsLoading = document.getElementById("questions-loading");
    const questionsTableWrapper = document.getElementById("questions-table-wrapper");
    const questionsTableBody = document.getElementById("questions-table-body");
    const questionsPagination = document.getElementById("questions-pagination");
    const btnAddQuestion = document.getElementById("btn-add-question");

    const questionEditor = document.getElementById("question-editor");
    const editorTitle = document.getElementById("editor-title");
    const questionText = document.getElementById("question-text");
    const optionInputs = [
        document.getElementById("option-0"),
        document.getElementById("option-1"),
        document.getElementById("option-2"),
        document.getElementById("option-3"),
    ];
    const correctRadios = document.querySelectorAll('input[name="correct-option"]');
    const btnSaveQuestion = document.getElementById("btn-save-question");
    const btnCancelQuestion = document.getElementById("btn-cancel-question");
    const questionFormError = document.getElementById("question-form-error");

    const deleteModal = document.getElementById("delete-modal");
    const deleteModalMessage = document.getElementById("delete-modal-message");
    const deleteModalWarning = document.getElementById("delete-modal-warning");
    const deleteModalTests = document.getElementById("delete-modal-tests");
    const btnConfirmDelete = document.getElementById("btn-confirm-delete");
    const btnCancelDelete = document.getElementById("btn-cancel-delete");

    // ---------- Error display ----------
    function showError(msg) {
        if (errorDiv) {
            errorDiv.textContent = msg;
            errorDiv.classList.remove("hidden");
        }
        console.error("[question-bank]", msg);
    }

    function hideError() {
        if (errorDiv) {
            errorDiv.classList.add("hidden");
        }
    }

    // ---------- API Calls ----------
    async function fetchCourses() {
        dbg("fetchCourses()");
        const resp = await fetch("/courses");
        if (!resp.ok) throw new Error("Failed to fetch courses");
        const data = await resp.json();
        return data.courses || [];
    }

    async function createCourse(code, name, academic_year, class_group) {
        dbg("createCourse()", code, name, academic_year, class_group);
        const resp = await fetch("/courses", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                code: code,
                name: name,
                academic_year: academic_year,
                class_group: class_group,
                teacher_dni: teacherDni,
            }),
        });
        return await resp.json();
    }

    async function fetchQuestions(courseId) {
        dbg("fetchQuestions() for course", courseId);
        const url = `/api/question-bank?teacher_dni=${encodeURIComponent(teacherDni)}&course_id=${courseId}`;
        const resp = await fetch(url);
        if (!resp.ok) throw new Error("Failed to fetch questions");
        const data = await resp.json();
        if (data.error) throw new Error(data.error);
        return data.questions || [];
    }

    async function fetchQuestion(questionId) {
        dbg("fetchQuestion()", questionId);
        const url = `/api/question-bank/${questionId}?teacher_dni=${encodeURIComponent(teacherDni)}`;
        const resp = await fetch(url);
        if (!resp.ok) throw new Error("Failed to fetch question");
        const data = await resp.json();
        if (data.error) throw new Error(data.error);
        return data.question;
    }

    async function saveQuestion(questionData) {
        dbg("saveQuestion()", questionData);
        const isEdit = questionData.id != null;
        const url = isEdit ? `/api/question-bank/${questionData.id}` : "/api/question-bank";
        const method = isEdit ? "PUT" : "POST";

        const resp = await fetch(url, {
            method: method,
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                teacher_dni: teacherDni,
                course_id: selectedCourseId,
                question_text: questionData.question_text,
                options: questionData.options,
            }),
        });
        return await resp.json();
    }

    async function deleteQuestion(questionId, cascade = false) {
        dbg("deleteQuestion()", questionId, "cascade=", cascade);
        const url = `/api/question-bank/${questionId}?teacher_dni=${encodeURIComponent(teacherDni)}&cascade=${cascade}`;
        const resp = await fetch(url, { method: "DELETE" });
        return await resp.json();
    }

    // ---------- UI Functions ----------
    function populateCourseSelect() {
        courseSelect.innerHTML = '<option value="">-- Select a course --</option>';
        courses.forEach((c) => {
            const opt = document.createElement("option");
            opt.value = c.id;
            opt.textContent = `${c.code} - ${c.name}`;
            courseSelect.appendChild(opt);
        });
    }

    function renderQuestionsTable() {
        questionsTableBody.innerHTML = "";

        if (questions.length === 0) {
            questionsEmpty.classList.remove("hidden");
            questionsTableWrapper.classList.add("hidden");
            questionsPagination.classList.add("hidden");
            questionsEmpty.innerHTML = "<p>No questions in this course yet. Click 'Add Question' to create one.</p>";
            return;
        }

        questionsEmpty.classList.add("hidden");
        questionsTableWrapper.classList.remove("hidden");

        // Pagination
        const totalPages = Math.ceil(questions.length / questionsPerPage);
        const startIdx = (currentPage - 1) * questionsPerPage;
        const endIdx = startIdx + questionsPerPage;
        const pageQuestions = questions.slice(startIdx, endIdx);

        pageQuestions.forEach((q, idx) => {
            const row = document.createElement("tr");
            const globalIdx = startIdx + idx + 1;

            // Question number
            const tdNum = document.createElement("td");
            tdNum.textContent = globalIdx;
            row.appendChild(tdNum);

            // Question text (truncated)
            const tdText = document.createElement("td");
            tdText.className = "question-text-cell";
            const textDiv = document.createElement("div");
            textDiv.className = "question-text-preview";
            textDiv.textContent = q.question_text;
            textDiv.title = q.question_text; // Full text on hover
            tdText.appendChild(textDiv);
            row.appendChild(tdText);

            // Options count (we'll show as "4 options" since we load details on edit)
            const tdOptions = document.createElement("td");
            tdOptions.innerHTML = '<span class="options-preview">4 options</span>';
            row.appendChild(tdOptions);

            // Actions
            const tdActions = document.createElement("td");
            tdActions.className = "action-buttons";

            const editBtn = document.createElement("button");
            editBtn.className = "btn-small";
            editBtn.textContent = "✏️ Edit";
            editBtn.addEventListener("click", () => openEditQuestion(q.id));
            tdActions.appendChild(editBtn);

            const deleteBtn = document.createElement("button");
            deleteBtn.className = "btn-small btn-danger";
            deleteBtn.textContent = "🗑️";
            deleteBtn.addEventListener("click", () => openDeleteModal(q.id));
            tdActions.appendChild(deleteBtn);

            row.appendChild(tdActions);
            questionsTableBody.appendChild(row);
        });

        renderPagination(totalPages);
    }

    function renderPagination(totalPages) {
        if (totalPages <= 1) {
            questionsPagination.classList.add("hidden");
            return;
        }

        questionsPagination.classList.remove("hidden");
        questionsPagination.innerHTML = `
            <button id="prev-page" type="button" ${currentPage === 1 ? "disabled" : ""}>← Prev</button>
            <span>Page ${currentPage} of ${totalPages}</span>
            <button id="next-page" type="button" ${currentPage === totalPages ? "disabled" : ""}>Next →</button>
        `;

        document.getElementById("prev-page").addEventListener("click", () => {
            if (currentPage > 1) {
                currentPage--;
                renderQuestionsTable();
            }
        });

        document.getElementById("next-page").addEventListener("click", () => {
            if (currentPage < totalPages) {
                currentPage++;
                renderQuestionsTable();
            }
        });
    }

    function clearQuestionEditor() {
        questionText.value = "";
        optionInputs.forEach((input) => (input.value = ""));
        correctRadios.forEach((radio) => (radio.checked = false));
        correctRadios[0].checked = true; // Default to first option
        questionFormError.textContent = "";
        editingQuestionId = null;
    }

    function openAddQuestion() {
        dbg("openAddQuestion()");
        clearQuestionEditor();
        editorTitle.textContent = "➕ Add New Question";
        questionEditor.classList.remove("hidden");
        questionText.focus();
    }

    async function openEditQuestion(questionId) {
        dbg("openEditQuestion()", questionId);
        try {
            questionsLoading.classList.remove("hidden");
            const q = await fetchQuestion(questionId);
            questionsLoading.classList.add("hidden");

            editingQuestionId = questionId;
            editorTitle.textContent = "✏️ Edit Question";
            questionText.value = q.question_text;

            // Fill options
            q.options.forEach((opt, idx) => {
                if (idx < 4) {
                    optionInputs[idx].value = opt.text;
                    if (opt.is_correct) {
                        correctRadios[idx].checked = true;
                    }
                }
            });

            questionFormError.textContent = "";
            questionEditor.classList.remove("hidden");
            questionText.focus();
        } catch (e) {
            showError("Failed to load question: " + e.message);
            questionsLoading.classList.add("hidden");
        }
    }

    function closeQuestionEditor() {
        questionEditor.classList.add("hidden");
        clearQuestionEditor();
    }

    async function handleSaveQuestion() {
        dbg("handleSaveQuestion()");
        questionFormError.textContent = "";

        const text = questionText.value.trim();
        if (!text) {
            questionFormError.textContent = "Question text is required";
            return;
        }

        const options = [];
        let correctIdx = -1;
        correctRadios.forEach((radio, idx) => {
            if (radio.checked) correctIdx = idx;
        });

        for (let i = 0; i < 4; i++) {
            const optText = optionInputs[i].value.trim();
            if (!optText) {
                questionFormError.textContent = `Option ${String.fromCharCode(65 + i)} is required`;
                return;
            }
            options.push({
                text: optText,
                is_correct: i === correctIdx,
            });
        }

        try {
            btnSaveQuestion.disabled = true;
            btnSaveQuestion.textContent = "Saving...";

            const result = await saveQuestion({
                id: editingQuestionId,
                question_text: text,
                options: options,
            });

            if (result.error) {
                questionFormError.textContent = result.error;
                return;
            }

            // Success - reload questions
            closeQuestionEditor();
            await loadQuestions();
        } catch (e) {
            questionFormError.textContent = "Failed to save: " + e.message;
        } finally {
            btnSaveQuestion.disabled = false;
            btnSaveQuestion.textContent = "💾 Save Question";
        }
    }

    function openDeleteModal(questionId) {
        dbg("openDeleteModal()", questionId);
        deleteQuestionId = questionId;
        deleteQuestionUsedInTests = [];

        // Reset modal
        deleteModalWarning.classList.add("hidden");
        deleteModalTests.innerHTML = "";
        deleteModalMessage.textContent = "Are you sure you want to delete this question?";

        deleteModal.classList.remove("hidden");
    }

    function closeDeleteModal() {
        deleteModal.classList.add("hidden");
        deleteQuestionId = null;
        deleteQuestionUsedInTests = [];
    }

    async function handleConfirmDelete() {
        dbg("handleConfirmDelete()", deleteQuestionId);
        if (!deleteQuestionId) return;

        try {
            btnConfirmDelete.disabled = true;
            btnConfirmDelete.textContent = "Deleting...";

            // First try without cascade
            let result = await deleteQuestion(deleteQuestionId, false);

            if (result.error && result.used_in_tests) {
                // Question is used in tests - show warning and ask for cascade
                deleteQuestionUsedInTests = result.used_in_tests;
                deleteModalWarning.classList.remove("hidden");
                deleteModalTests.innerHTML = "";
                result.used_in_tests.forEach((title) => {
                    const li = document.createElement("li");
                    li.textContent = title;
                    deleteModalTests.appendChild(li);
                });
                deleteModalMessage.textContent = "This question is used in tests.";
                btnConfirmDelete.textContent = "🗑️ Delete Anyway";
                btnConfirmDelete.disabled = false;

                // Change handler to cascade delete
                btnConfirmDelete.onclick = async () => {
                    btnConfirmDelete.disabled = true;
                    btnConfirmDelete.textContent = "Deleting...";
                    const cascadeResult = await deleteQuestion(deleteQuestionId, true);
                    if (cascadeResult.error) {
                        showError(cascadeResult.error);
                    } else {
                        closeDeleteModal();
                        await loadQuestions();
                    }
                    btnConfirmDelete.disabled = false;
                    btnConfirmDelete.textContent = "🗑️ Delete";
                    btnConfirmDelete.onclick = handleConfirmDelete;
                };
                return;
            }

            if (result.error) {
                showError(result.error);
                closeDeleteModal();
                return;
            }

            // Success
            closeDeleteModal();
            await loadQuestions();
        } catch (e) {
            showError("Failed to delete: " + e.message);
        } finally {
            btnConfirmDelete.disabled = false;
            btnConfirmDelete.textContent = "🗑️ Delete";
        }
    }

    async function loadQuestions() {
        if (!selectedCourseId) {
            questions = [];
            questionsEmpty.classList.remove("hidden");
            questionsTableWrapper.classList.add("hidden");
            questionsPagination.classList.add("hidden");
            questionsEmpty.innerHTML = "<p>Select a course to view its questions, or create a new course first.</p>";
            return;
        }

        try {
            questionsLoading.classList.remove("hidden");
            questionsEmpty.classList.add("hidden");
            questionsTableWrapper.classList.add("hidden");

            questions = await fetchQuestions(selectedCourseId);
            currentPage = 1;
            renderQuestionsTable();
        } catch (e) {
            showError("Failed to load questions: " + e.message);
            questions = [];
            renderQuestionsTable();
        } finally {
            questionsLoading.classList.add("hidden");
        }
    }

    // ---------- Event Handlers ----------
    function initEventHandlers() {
        // Course select change
        courseSelect.addEventListener("change", async () => {
            const value = courseSelect.value;
            selectedCourseId = value ? parseInt(value, 10) : null;
            btnAddQuestion.disabled = !selectedCourseId;
            jsonFileInput.disabled = !selectedCourseId;
            btnUploadJson.disabled = !selectedCourseId;
            btnDownloadJson.disabled = !selectedCourseId;
            closeQuestionEditor();
            await loadQuestions();
        });

        // New course button
        btnNewCourse.addEventListener("click", () => {
            newCourseForm.classList.toggle("hidden");
            newCourseCode.value = "";
            newCourseName.value = "";
            courseFormError.textContent = "";
            if (!newCourseForm.classList.contains("hidden")) {
                newCourseCode.focus();
            }
        });

        // Save course
        btnSaveCourse.addEventListener("click", async () => {
            courseFormError.textContent = "";
            const code = newCourseCode.value.trim();
            const name = newCourseName.value.trim();

            if (!code) {
                courseFormError.textContent = "Course code is required";
                return;
            }
            if (!name) {
                courseFormError.textContent = "Course name is required";
                return;
            }

            // Extract academic year from first 4 characters of code
            const yearStr = code.substring(0, 4);
            const year = parseInt(yearStr, 10);
            if (isNaN(year) || yearStr.length !== 4) {
                courseFormError.textContent = "Course code must start with 4 digits (e.g., 2526-45810-A)";
                return;
            }

            // Extract class group from last segment after last dash
            const parts = code.split("-");
            const group = parts[parts.length - 1];
            if (!group) {
                courseFormError.textContent = "Course code must end with class group (e.g., 2526-45810-A)";
                return;
            }

            try {
                btnSaveCourse.disabled = true;
                btnSaveCourse.textContent = "Saving...";

                const result = await createCourse(code, name, year, group);
                if (result.error) {
                    courseFormError.textContent = result.error;
                    return;
                }

                // Success - reload courses and select the new one
                courses = await fetchCourses();
                populateCourseSelect();
                courseSelect.value = result.course.id;
                selectedCourseId = result.course.id;
                btnAddQuestion.disabled = false;
                jsonFileInput.disabled = false;
                btnUploadJson.disabled = false;
                newCourseForm.classList.add("hidden");
                await loadQuestions();
            } catch (e) {
                courseFormError.textContent = "Failed to create course: " + e.message;
            } finally {
                btnSaveCourse.disabled = false;
                btnSaveCourse.textContent = "💾 Save Course";
            }
        });

        // Cancel course
        btnCancelCourse.addEventListener("click", () => {
            newCourseForm.classList.add("hidden");
        });

        // Upload JSON button
        btnUploadJson.addEventListener("click", async () => {
            const file = jsonFileInput.files[0];
            if (!file) {
                uploadResult.textContent = "Please select a JSON file first";
                uploadResult.style.color = "var(--error)";
                return;
            }

            if (!selectedCourseId) {
                uploadResult.textContent = "Please select a course first";
                uploadResult.style.color = "var(--error)";
                return;
            }

            const shouldReplace = replaceQuestionsCheckbox.checked;

            try {
                btnUploadJson.disabled = true;
                btnUploadJson.textContent = "Uploading...";
                uploadResult.textContent = "Reading file...";
                uploadResult.style.color = "var(--text-muted)";

                // Read file content
                const content = await file.text();
                const jsonData = JSON.parse(content);

                // Get the selected course code
                const selectedCourse = courses.find(c => c.id === selectedCourseId);
                if (!selectedCourse) {
                    uploadResult.textContent = "Selected course not found";
                    uploadResult.style.color = "var(--error)";
                    return;
                }

                // Set the course code and replace flag in the JSON data
                jsonData.course_code = selectedCourse.code;
                jsonData.replace_existing = shouldReplace;

                if (shouldReplace) {
                    uploadResult.textContent = "Deleting existing questions and uploading new ones...";
                } else {
                    uploadResult.textContent = "Uploading questions...";
                }

                // Upload to API
                const resp = await fetch("/api/question-bank/upload", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(jsonData)
                });

                const result = await resp.json();

                if (result.error) {
                    uploadResult.textContent = result.error;
                    uploadResult.style.color = "var(--error)";
                    return;
                }

                let message = result.message;
                if (result.deleted_count) {
                    message = `Deleted ${result.deleted_count} existing question(s). ` + message;
                }
                if (result.deleted_answers_count) {
                    message += ` (${result.deleted_answers_count} student answer(s) were also removed)`;
                }
                if (result.errors && result.errors.length > 0) {
                    message += "\n\nWarnings:\n" + result.errors.join("\n");
                }

                uploadResult.textContent = message;
                uploadResult.style.color = "var(--success)";

                // Download CSV if available
                if (result.csv_data) {
                    const blob = new Blob([result.csv_data], { type: "text/csv" });
                    const url = URL.createObjectURL(blob);
                    const a = document.createElement("a");
                    a.href = url;
                    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
                    a.download = `questions_upload_${selectedCourse.code}_${timestamp}.csv`;
                    document.body.appendChild(a);
                    a.click();
                    document.body.removeChild(a);
                    URL.revokeObjectURL(url);

                    uploadResult.textContent = message + "\n\n✅ CSV report downloaded";
                }

                // Clear file input and reload questions
                jsonFileInput.value = "";
                replaceQuestionsCheckbox.checked = false;
                await loadQuestions();

            } catch (e) {
                uploadResult.textContent = "Error: " + e.message;
                uploadResult.style.color = "var(--error)";
                dbg("Upload error:", e);
            } finally {
                btnUploadJson.disabled = false;
                btnUploadJson.textContent = "📤 Upload Questions";
            }
        });

        // Download JSON button
        btnDownloadJson.addEventListener("click", async () => {
            if (!selectedCourseId) {
                downloadResult.textContent = "Please select a course first";
                downloadResult.style.color = "var(--error)";
                return;
            }

            try {
                btnDownloadJson.disabled = true;
                btnDownloadJson.textContent = "Downloading...";
                downloadResult.textContent = "Fetching questions...";
                downloadResult.style.color = "var(--text-muted)";

                // Get the selected course code
                const selectedCourse = courses.find(c => c.id === selectedCourseId);
                if (!selectedCourse) {
                    downloadResult.textContent = "Selected course not found";
                    downloadResult.style.color = "var(--error)";
                    return;
                }

                // Fetch questions as JSON
                const resp = await fetch(`/api/question-bank/export?course_code=${encodeURIComponent(selectedCourse.code)}`);
                const result = await resp.json();

                if (result.error) {
                    downloadResult.textContent = result.error;
                    downloadResult.style.color = "var(--error)";
                    return;
                }

                // Create a downloadable file
                const jsonString = JSON.stringify(result, null, 2);
                const blob = new Blob([jsonString], { type: "application/json" });
                const url = URL.createObjectURL(blob);

                // Create a temporary link and click it to download
                const a = document.createElement("a");
                a.href = url;
                a.download = `questions_${selectedCourse.code}.json`;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);

                const questionCount = result.questions ? result.questions.length : 0;
                downloadResult.textContent = `Successfully downloaded ${questionCount} question(s)`;
                downloadResult.style.color = "var(--success)";

            } catch (e) {
                downloadResult.textContent = "Error: " + e.message;
                downloadResult.style.color = "var(--error)";
                dbg("Download error:", e);
            } finally {
                btnDownloadJson.disabled = false;
                btnDownloadJson.textContent = "📥 Download Questions";
            }
        });

        // Add question
        btnAddQuestion.addEventListener("click", openAddQuestion);

        // Save question
        btnSaveQuestion.addEventListener("click", handleSaveQuestion);

        // Cancel question
        btnCancelQuestion.addEventListener("click", closeQuestionEditor);

        // Delete modal
        btnConfirmDelete.addEventListener("click", handleConfirmDelete);
        btnCancelDelete.addEventListener("click", closeDeleteModal);

        // Close modal on backdrop click
        deleteModal.addEventListener("click", (e) => {
            if (e.target === deleteModal) {
                closeDeleteModal();
            }
        });

        // Escape key to close modals/editors
        document.addEventListener("keydown", (e) => {
            if (e.key === "Escape") {
                if (!deleteModal.classList.contains("hidden")) {
                    closeDeleteModal();
                } else if (!questionEditor.classList.contains("hidden")) {
                    closeQuestionEditor();
                } else if (!newCourseForm.classList.contains("hidden")) {
                    newCourseForm.classList.add("hidden");
                }
            }
        });
    }

    // ---------- Check Teacher Access ----------
    async function checkAccess() {
        teacherDni = getCookie("quiz_dni");
        dbg("Checking access for DNI:", teacherDni);

        if (!teacherDni) {
            accessDenied.classList.remove("hidden");
            return false;
        }

        // Verify teacher by trying to access teacher dashboard
        try {
            const resp = await fetch(`/teacher/dashboard_overview?teacher_dni=${encodeURIComponent(teacherDni)}`);
            if (!resp.ok) {
                accessDenied.classList.remove("hidden");
                return false;
            }
            const data = await resp.json();
            if (data.error) {
                accessDenied.classList.remove("hidden");
                return false;
            }
            return true;
        } catch (e) {
            dbg("Access check failed:", e);
            accessDenied.classList.remove("hidden");
            return false;
        }
    }

    // ---------- Initialize ----------
    async function init() {
        dbg("Initializing question bank...");

        initTheme();
        initNavigation();
        loadVersion();

        const hasAccess = await checkAccess();
        if (!hasAccess) {
            dbg("Access denied");
            return;
        }

        mainContent.classList.remove("hidden");

        // Force course selector styling
        if (courseSelect) {
            courseSelect.style.fontWeight = "bold";
            courseSelect.style.minWidth = "300px";
            // Force white color in dark mode
            const updateColor = () => {
                if (document.body.classList.contains("dark")) {
                    courseSelect.style.color = "#ffffff";
                } else {
                    courseSelect.style.color = "";
                }
            };
            updateColor();
            // Watch for theme changes
            const themeBtn = document.getElementById("theme-toggle");
            if (themeBtn) {
                themeBtn.addEventListener("click", () => setTimeout(updateColor, 10));
            }
        }

        initEventHandlers();

        // Load courses
        try {
            courses = await fetchCourses();
            populateCourseSelect();

            if (courses.length === 0) {
                questionsEmpty.innerHTML = "<p>No courses found. Create a new course to get started.</p>";
            }
        } catch (e) {
            showError("Failed to load courses: " + e.message);
        }
    }

    // ---------- Start ----------
    document.addEventListener("DOMContentLoaded", init);
})();
